import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../models/news_data.dart';
import '../../services/api_service.dart';
import 'news_detail_view.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isLoading = true;
  List<NewsData> _newsList = [];
  
  final List<String> _categories = ['Semua', 'Terkini', 'Kriminalitas', 'Lalu Lintas'];
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetched = await ApiService.fetchNews();
      if (mounted) {
        setState(() {
          _newsList = fetched;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _newsList = AppDatabase.newsArticles;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTrendingCard(NewsData trending) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => NewsDetailView(news: trending)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F0FF), // Light lavender background
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TRENDING',
              style: TextStyle(
                color: Color(0xFF8B5CF6), // Purple
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              trending.title,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trending.summary,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  trending.date,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                const Text(
                  '·',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(
                  trending.author,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNews = _newsList.where((n) {
      final matchesSearch = n.title.toLowerCase().contains(_searchQuery) ||
          n.summary.toLowerCase().contains(_searchQuery);
      
      if (!matchesSearch) return false;
      
      if (_selectedCategory == 'Semua' || _selectedCategory == 'Terkini') {
        return true;
      } else if (_selectedCategory == 'Kriminalitas') {
        return n.category.toLowerCase().contains('keamanan') || 
               n.category.toLowerCase().contains('kriminalitas') ||
               n.category.toLowerCase().contains('kategori');
      } else if (_selectedCategory == 'Lalu Lintas') {
        return n.category.toLowerCase().contains('lalu lintas') ||
               n.category.toLowerCase().contains('jalan');
      }
      return true;
    }).toList();

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Tag
              const Text(
                'BERITA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),

              // Page Title
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: 'Info ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: 'ketertiban',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: ' kota.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Underlined Search Bar Input
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Cari berita...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  prefixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 20),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0F172A), width: 1.5),
                  ),
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Category Tabs Pills
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0B0F19) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0B0F19) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Scrollable News Feed list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0B0F19)))
                    : filteredNews.isEmpty && _selectedCategory != 'Semua'
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                                SizedBox(height: 12),
                                Text(
                                  'Tidak ada berita ditemukan',
                                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // Display Trending Card on top only when category is "Semua", search is empty, and list has elements
                              if (_selectedCategory == 'Semua' && _searchQuery.isEmpty && _newsList.isNotEmpty) ...[
                                _buildTrendingCard(_newsList.first),
                                const SizedBox(height: 12),
                              ],
                              
                              if (filteredNews.isEmpty && _selectedCategory == 'Semua')
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 40.0),
                                    child: Text(
                                      'Tidak ada berita tambahan saat ini.',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredNews.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    color: Color(0xFFF1F5F9),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final news = filteredNews[index];
                                    
                                    String displayCat = news.category.toUpperCase();
                                    if (displayCat == 'KEAMANAN') displayCat = 'KRIMINALITAS';

                                    return InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => NewsDetailView(news: news)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayCat,
                                              style: const TextStyle(
                                                color: Color(0xFF8B5CF6), // Purple
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              news.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(Icons.schedule_outlined, size: 13, color: Color(0xFF94A3B8)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  news.date,
                                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  '·',
                                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  '3 mnt baca',
                                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 80), // Padding space for navigation bar
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
