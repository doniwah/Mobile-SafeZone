import 'package:flutter/material.dart';
import '../../models/news_data.dart';
import '../../widgets/desktop_frame.dart';

class NewsDetailView extends StatelessWidget {
  final NewsData news;
  const NewsDetailView({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return DesktopFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NewsDetailViewContent(news: news),
      ),
    );
  }
}

class NewsDetailViewContent extends StatelessWidget {
  final NewsData news;
  const NewsDetailViewContent({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 24),

            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                news.imagePath,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.image_rounded, size: 40, color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                news.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF0F172A), 
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Author & Date Row
            Row(
              children: [
                const Icon(Icons.account_circle_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  news.author,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  news.date,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 20),

            // Content
            Text(
              news.content,
              style: const TextStyle(
                fontSize: 14.5, 
                color: Color(0xFF334155), 
                height: 1.6, 
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
