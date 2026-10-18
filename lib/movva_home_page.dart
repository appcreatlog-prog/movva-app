// lib/movva_home_page.dart
// Tela inicial do MOVVA (preto + laranja), baseada na imagem de referência.
// Arquivo NOVO: não altera nada do que já existe. Os dados e as ações
// chegam por parâmetros, então nada aqui é inventado nem decorativo.

import 'package:flutter/material.dart';

class MovvaColors {
  static const black = Color(0xFF070707);
  static const card = Color(0xFF121212);
  static const line = Color(0xFF262626);
  static const orange = Color(0xFFFF4D17);
  static const orangeSoft = Color(0xFFFF7A45);
  static const muted = Color(0xFF9A9A9A);
}

/// Página completa: barra inferior no celular, barra lateral no computador.
/// Se o main.dart já tem navegação própria, use só [MovvaHomeContent].
class MovvaHomePage extends StatelessWidget {
  const MovvaHomePage({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    required this.content,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final Widget content;

  static const _items = [
    (Icons.home_rounded, 'Início'),
    (Icons.explore_outlined, 'Explorar'),
    (Icons.play_circle_outline, 'Registrar'),
    (Icons.emoji_events_outlined, 'Desafios'),
    (Icons.person_outline, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      if (wide) {
        return Scaffold(
          backgroundColor: MovvaColors.black,
          body: Row(children: [
            NavigationRail(
              backgroundColor: MovvaColors.card,
              selectedIndex: selectedIndex,
              onDestinationSelected: onNavigate,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: MovvaColors.orange),
              selectedLabelTextStyle: const TextStyle(color: MovvaColors.orange),
              unselectedIconTheme: const IconThemeData(color: MovvaColors.muted),
              unselectedLabelTextStyle: const TextStyle(color: MovvaColors.muted),
              indicatorColor: MovvaColors.orange.withOpacity(0.15),
              destinations: [
                for (final i in _items)
                  NavigationRailDestination(icon: Icon(i.$1), label: Text(i.$2)),
              ],
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: content,
                ),
              ),
            ),
          ]),
        );
      }
      return Scaffold(
        backgroundColor: MovvaColors.black,
        body: SafeArea(bottom: false, child: content),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: MovvaColors.card,
            border: Border(top: BorderSide(color: MovvaColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(children: [
                for (var n = 0; n < _items.length; n++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onNavigate(n),
                      child: _NavItem(
                        icon: _items[n].$1,
                        label: _items[n].$2,
                        selected: n == selectedIndex,
                        highlight: n == 2,
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.highlight,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = (selected || highlight) ? MovvaColors.orange : MovvaColors.muted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        highlight
            ? Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MovvaColors.orange, width: 2),
                ),
                child: Icon(icon, color: color, size: 22),
              )
            : Icon(icon, color: color, size: 24),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

/// Conteúdo da tela inicial. Valores nulos aparecem como "—".
class MovvaHomeContent extends StatelessWidget {
  const MovvaHomeContent({
    super.key,
    this.userName,
    this.avatarUrl,
    this.bannerAsset, // ex.: 'assets/banner_corrida.jpg' (declare no pubspec.yaml)
    this.distanceKm,
    this.duration,
    this.pacePerKm,
    this.calories,
    this.weeklyKm,
    this.weeklyGoalKm = 50,
    this.hasNotifications = false,
    this.onStartRun,
    this.onStartRide,
    this.onOpenChallenges,
    this.onNotifications,
    this.onProfile,
  });

  final String? userName;
  final String? avatarUrl;
  final String? bannerAsset;
  final double? distanceKm;
  final Duration? duration;
  final Duration? pacePerKm;
  final int? calories;
  final double? weeklyKm;
  final double weeklyGoalKm;
  final bool hasNotifications;
  final VoidCallback? onStartRun;
  final VoidCallback? onStartRide;
  final VoidCallback? onOpenChallenges;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0
        ? '$h:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
        : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final done = weeklyKm ?? 0;
    final progress = weeklyGoalKm <= 0 ? 0.0 : (done / weeklyGoalKm).clamp(0.0, 1.0);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _hero(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _statsCard(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircleAction(
                icon: Icons.directions_run,
                title: 'CORRIDA',
                subtitle: 'Registrar corrida',
                onTap: onStartRun,
              ),
              _CircleAction(
                icon: Icons.directions_bike,
                title: 'PEDAL',
                subtitle: 'Registrar pedal',
                onTap: onStartRide,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DESAFIOS',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              GestureDetector(
                onTap: onOpenChallenges,
                child: const Text('Ver todos os desafios  ›',
                    style: TextStyle(color: MovvaColors.orangeSoft, fontSize: 13)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MovvaColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MovvaColors.line),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MovvaColors.orange, width: 2),
                  color: MovvaColors.orange.withOpacity(0.12),
                ),
                child: const Icon(Icons.landscape_outlined, color: MovvaColors.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Desafio da Semana',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Corra ${weeklyGoalKm.toStringAsFixed(0)} km nos próximos 7 dias',
                        style: const TextStyle(color: MovvaColors.muted, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: MovvaColors.line,
                            valueColor:
                                const AlwaysStoppedAnimation(MovvaColors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${done.toStringAsFixed(0)} / ${weeklyGoalKm.toStringAsFixed(0)} km',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return SizedBox(
      height: 360,
      child: Stack(fit: StackFit.expand, children: [
        if (bannerAsset != null)
          Image.asset(bannerAsset!, fit: BoxFit.cover, alignment: Alignment.topRight)
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B3A5C), Color(0xFFB5502B), Color(0xFF1A0E08)],
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, MovvaColors.black],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.show_chart, color: MovvaColors.orange, size: 34),
                const SizedBox(width: 8),
                const Text('MOVVA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w300)),
                const Spacer(),
                GestureDetector(
                  onTap: onProfile,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: MovvaColors.card,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white70, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onNotifications,
                  child: Stack(clipBehavior: Clip.none, children: [
                    const Icon(Icons.notifications_none, color: Colors.white),
                    if (hasNotifications)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: MovvaColors.orange, shape: BoxShape.circle),
                        ),
                      ),
                  ]),
                ),
              ]),
              const Spacer(),
              Text(
                userName == null || userName!.isEmpty
                    ? 'Olá! Pronto para hoje?'
                    : 'Olá, $userName! Pronto para hoje?',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text('VAMOS\nCORRER?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.05,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Registre sua atividade\ne continue evoluindo.',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onStartRun,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('INICIAR CORRIDA',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MovvaColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _statsCard() {
    final items = <(IconData, String, String, String)>[
      (Icons.straighten, 'DISTÂNCIA',
          distanceKm == null ? '—' : distanceKm!.toStringAsFixed(2).replaceAll('.', ','), 'km'),
      (Icons.timer_outlined, 'TEMPO', duration == null ? '—' : _fmt(duration!), ''),
      (Icons.speed, 'RITMO MÉDIO', pacePerKm == null ? '—' : _fmt(pacePerKm!), '/km'),
      (Icons.local_fire_department_outlined, 'CALORIAS',
          calories == null ? '—' : '$calories', ''),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: MovvaColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MovvaColors.line),
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Column(children: [
                Icon(items[i].$1, color: MovvaColors.orange, size: 20),
                const SizedBox(height: 6),
                Text(items[i].$2,
                    style: const TextStyle(color: MovvaColors.muted, fontSize: 9.5)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: items[i].$3,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  if (items[i].$4.isNotEmpty && items[i].$3 != '—')
                    TextSpan(
                        text: ' ${items[i].$4}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),
            if (i < items.length - 1)
              const VerticalDivider(color: MovvaColors.line, width: 1),
          ],
        ]),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MovvaColors.black,
          border: Border.all(color: MovvaColors.orange, width: 2.5),
          boxShadow: [
            BoxShadow(
                color: MovvaColors.orange.withOpacity(0.45),
                blurRadius: 22,
                spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MovvaColors.orange, size: 38),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(color: MovvaColors.muted, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}
