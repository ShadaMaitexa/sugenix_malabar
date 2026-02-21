import 'package:flutter/material.dart';
import 'package:sugenix/widgets/translated_text.dart';
import 'package:sugenix/services/language_service.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          'terms_and_conditions_title',
          fallback: 'Terms and Conditions',
          style: const TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: LanguageBuilder(
          builder: (context, languageCode) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  'terms_section_1_title',
                  '1. Acceptance of Terms',
                  'terms_section_1_content',
                  'By accessing and using Sugenix, you agree to be bound by these Terms and Conditions and all applicable laws and regulations.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  'terms_section_2_title',
                  '2. Medical Disclaimer',
                  'terms_section_2_content',
                  'Sugenix is a tool for diabetes management and should not be used as a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  'terms_section_3_title',
                  '3. User Privacy',
                  'terms_section_3_content',
                  'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using our service, you agree to the collection and use of information in accordance with our policy.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  'terms_section_4_title',
                  '4. Account Responsibilities',
                  'terms_section_4_content',
                  'You are responsible for maintaining the confidentiality of your account and password. You agree to notify us immediately of any unauthorized use of your account.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  context,
                  'terms_section_5_title',
                  '5. Limitation of Liability',
                  'terms_section_5_content',
                  'Sugenix and its creators shall not be liable for any direct, indirect, incidental, special, or consequential damages resulting from the use or inability to use the service.',
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Last updated: February 2026',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String titleKey,
      String titleFallback, String contentKey, String contentFallback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          titleKey,
          fallback: titleFallback,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 8),
        TranslatedText(
          contentKey,
          fallback: contentFallback,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
