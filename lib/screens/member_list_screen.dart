import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../providers/auth_provider.dart';
import '../models/member.dart';
import 'register_user_screen.dart';
import 'dart:async';

const Color _kBackgroundColor = Color(0xFF121212);
const Color _kCardColor = Color(0xFF1E1E1E);
const Color _kPrimaryColor = Color(0xFFFF8800);
const Color _kTextColor = Colors.white;
const Color _kSecondaryTextColor = Color(0xFFAAAAAA);
const Color _kErrorColor = Color(0xFFCF6679);

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});
  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<MemberProvider>(context, listen: false).fetchAndSetMembers());
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        Provider.of<MemberProvider>(context, listen: false).fetchAndSetMembers(query: query);
      }
    });
  }

  Future<void> _navigateToEditScreen(BuildContext context, Member member) async {
    await Navigator.push(context, MaterialPageRoute(builder: (ctx) => RegisterUserScreen(member: member)));
    if (mounted) {
      Provider.of<MemberProvider>(context, listen: false).fetchAndSetMembers();
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final isOwner = Provider.of<AuthProvider>(context, listen: false).isOwner;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBackgroundColor,
        appBar: AppBar(
          title: const Text('إدارة المشتركين', style: TextStyle(color: _kTextColor)),
          backgroundColor: _kCardColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: _kPrimaryColor),
              onPressed: () => memberProvider.fetchAndSetMembers(),
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: _kTextColor),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الإيميل...',
                  hintStyle: const TextStyle(color: _kSecondaryTextColor),
                  prefixIcon: const Icon(Icons.search, color: _kPrimaryColor),
                  fillColor: _kCardColor,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kPrimaryColor))
                  : memberProvider.members.isEmpty
                  ? const Center(child: Text('لا توجد نتائج.', style: TextStyle(color: _kSecondaryTextColor)))
                  : ListView.builder(
                itemCount: memberProvider.members.length,
                itemBuilder: (ctx, i) => _buildMemberCard(context, memberProvider.members[i], memberProvider, isOwner),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Member member, MemberProvider provider, bool isOwner) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: _kCardColor,
      child: ListTile(

        title: Text(member.name, style: const TextStyle(color: _kTextColor, fontWeight: FontWeight.bold)),
        subtitle: Text('أيام متبقية: ${member.remainingDays}', style: const TextStyle(color: _kSecondaryTextColor)),
        trailing: isOwner ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: _kPrimaryColor), onPressed: () => _navigateToEditScreen(context, member)),
            IconButton(icon: const Icon(Icons.delete, color: _kErrorColor), onPressed: () => provider.deleteMember(member.id)),
            // داخل ListTile في ملف الشاشة
            Text(
              'متبقي: ${member.remainingDays} يوم',
              style: TextStyle(
                color: member.remainingDays <= 3 ? Colors.red : Color(0xFFAAAAAA),
                fontSize: 12,
                fontWeight: member.remainingDays <= 3 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ) : null,
      ),
    );
  }
}