import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class AboutEasterEggScreen extends StatefulWidget {
  const AboutEasterEggScreen({Key? key}) : super(key: key);

  @override
  State<AboutEasterEggScreen> createState() => _AboutEasterEggScreenState();
}

class _AboutEasterEggScreenState extends State<AboutEasterEggScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _controller.forward();
    
    // Afficher le contenu après l'animation du nom
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppTheme.accentNeon.withOpacity(0.1),
              AppTheme.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Bouton retour
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // Contenu principal
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animation du nom avec séparation pecorio / dev
                      _buildAnimatedName(),
                      
                      const SizedBox(height: 40),
                      
                      // Contenu après l'animation
                      if (_showContent) ...[
                        _buildCuriousMessage(),
                        const SizedBox(height: 32),
                        _buildAboutSection(),
                        const SizedBox(height: 32),
                        _buildSupportSection(),
                        const SizedBox(height: 24),
                        _buildContactButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedName() {
    return Column(
      children: [
        // "pecorio" avec animation qui arrive de la gauche
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'pecorio',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentNeon,
                shadows: [
                  Shadow(
                    color: AppTheme.accentNeon.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            )
                .animate()
                .slideX(
                  begin: -2,
                  end: 0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: const Duration(milliseconds: 400)),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Trait de séparation animé
        Container(
          width: 150,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.accentNeon,
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0, 1),
              end: const Offset(1, 1),
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 800),
            )
            .fadeIn(delay: const Duration(milliseconds: 800)),
        
        const SizedBox(height: 8),
        
        // "dev" avec animation qui arrive de la droite
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'dev',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: AppTheme.accentSecondary,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: AppTheme.accentSecondary.withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
            )
                .animate()
                .slideX(
                  begin: 2,
                  end: 0,
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                )
                .fadeIn(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 400),
                ),
          ],
        ),
        
        // Effet de particules/étoiles autour
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          children: List.generate(
            5,
            (index) => Icon(
              Icons.star,
              size: 16,
              color: AppTheme.accentNeon.withOpacity(0.6),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.2, 1.2),
                  duration: Duration(milliseconds: 800 + (index * 100)),
                  delay: Duration(milliseconds: 1000 + (index * 200)),
                )
                .fadeIn(delay: Duration(milliseconds: 1000 + (index * 200))),
          ),
        ),
      ],
    );
  }

  Widget _buildCuriousMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentNeon.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search,
            size: 32,
            color: AppTheme.accentNeon,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .rotate(
                begin: -0.05,
                end: 0.05,
                duration: const Duration(seconds: 2),
              ),
          const SizedBox(height: 12),
          Text(
            'Eh bien, tu es curieux de fouiller dans la version de l\'app ! 🕵️',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 600));
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentNeon.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentNeon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppTheme.accentNeon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'À propos du créateur',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.cake, '17 ans lors de la création de cette app'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person, 'Développeur solo sur ce projet'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.update, 'Projet maintenu activement'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💙 Merci d\'utiliser NEO Stream ! Ton soutien compte énormément.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200))
        .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200));
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accentNeon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentNeon.withOpacity(0.1),
            AppTheme.accentSecondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentNeon.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            size: 32,
            color: Colors.pink,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: const Duration(milliseconds: 800),
              ),
          const SizedBox(height: 16),
          const Text(
            'Tu souhaites me soutenir ?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tu peux m\'aider de plusieurs façons :',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            Icons.coffee,
            'Faire un don',
            'Via Ko-fi pour soutenir le projet',
            () => _launchUrl('https://ko-fi.com/pecorio'),
          ),
          const SizedBox(height: 12),
          _buildSupportOption(
            Icons.email,
            'Envoyer un message',
            'Questions, suggestions ou collaborations',
            () => _launchEmail(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Je peux vous aider gratuitement ou de manière rémunérée selon votre demande.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '(Non négociable - je décide 😊)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.accentNeon,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 400))
        .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 400));
  }

  Widget _buildSupportOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentNeon.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentNeon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.accentNeon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security, color: AppTheme.accentSecondary, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Email sécurisé Firefox Relay',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 600))
        .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 600));
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir le lien: $url'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    const email = '2tc1ubwzr@mozmail.com';
    const subject = 'Contact depuis NEO Stream';
    const body = 'Bonjour pecorio,\n\nJe vous contacte concernant NEO Stream...\n\n';
    
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          // Fallback: copier l'email dans le presse-papier
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email: $email (copiez-le manuellement)'),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email: $email'),
            backgroundColor: AppTheme.accentNeon,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
