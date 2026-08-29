import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../models/ad_item.dart';
import '../services/ads_service.dart';

/// Bandeau publicitaire (annonceurs locaux) qui défile automatiquement,
/// comme celui déjà en place sur le site web (`index.html`,
/// `loadAdCarousel()`) — mêmes deux emplacements possibles : [zone]
/// `'catalog'` (catalogue élève) ou `'dashboard'` ("Mes documents"
/// professeur). Entièrement invisible (aucun espace réservé) tant qu'aucune
/// annonce active n'existe pour cette zone, pour ne jamais gêner l'écran
/// avant que l'admin en ait créé une depuis `admin.html`.
class AdCarousel extends StatefulWidget {
  final String zone;

  const AdCarousel({super.key, required this.zone});

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  late final AdsService _service;
  late Future<List<AdItem>> _future;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _service = AdsService(apiClient: apiClient);
    _future = _service.fetchBannerAds(zone: widget.zone);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdItem>>(
      future: _future,
      builder: (context, snapshot) {
        final ads = snapshot.data ?? const <AdItem>[];
        if (snapshot.connectionState != ConnectionState.done || ads.isEmpty) {
          // En chargement, en erreur, ou pas d'annonce active pour cette
          // zone : rien à afficher (voir commentaire de classe ci-dessus) —
          // une pub qui échoue à charger ne doit jamais se voir ni bloquer
          // le reste de l'écran.
          return const SizedBox.shrink();
        }
        return _AdCarouselView(ads: ads, service: _service);
      },
    );
  }
}

class _AdCarouselView extends StatefulWidget {
  final List<AdItem> ads;
  final AdsService service;

  const _AdCarouselView({required this.ads, required this.service});

  @override
  State<_AdCarouselView> createState() => _AdCarouselViewState();
}

class _AdCarouselViewState extends State<_AdCarouselView> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  final Set<String> _reportedImpressions = {};

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _reportImpression(widget.ads.first);
    if (widget.ads.length > 1) {
      // Même rythme que le carrousel du site web (défilement toutes les 6s).
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % widget.ads.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _reportImpression(AdItem ad) {
    // Une seule fois par annonce et par affichage de l'écran, pas à chaque
    // fois qu'elle revient à l'écran en boucle.
    if (_reportedImpressions.add(ad.id)) {
      widget.service.reportImpression(ad.id);
    }
  }

  Future<void> _onTap(AdItem ad) async {
    widget.service.reportClick(ad.id);
    final target = ad.targetUrl;
    if (target == null || target.isEmpty) return;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Lien non ouvrable (rare) — jamais bloquant pour une simple pub.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = widget.ads;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 90,
              child: PageView.builder(
                controller: _controller,
                itemCount: ads.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _reportImpression(ads[i]);
                },
                itemBuilder: (context, i) => _AdSlide(ad: ads[i], onTap: () => _onTap(ads[i])),
              ),
            ),
          ),
          if (ads.length > 1) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(ads.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.brandBlue
                        : AppTheme.brandBlue.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdSlide extends StatelessWidget {
  final AdItem ad;
  final VoidCallback onTap;

  const _AdSlide({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ad.imageUrl != null)
            Image.network(
              ad.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _fallback();
              },
            )
          else
            _fallback(),
          Positioned(
            left: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'Annonce',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppTheme.brandBlue.withValues(alpha: 0.08),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        ad.advertiserName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.brandBlue,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
