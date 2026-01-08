
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dual-column selector widget for artist and song selection
/// Left column: Artists, Right column: Songs
class DualColumnSelector extends StatefulWidget {
  final List<String> artists;
  final List<SongItem> songs;
  final String? selectedArtist;
  final String? selectedSongId;
  final Function(String artist) onArtistSelected;
  final Function(String songId) onSongSelected;
  final bool disabled;

  const DualColumnSelector({
    super.key,
    required this.artists,
    required this.songs,
    this.selectedArtist,
    this.selectedSongId,
    required this.onArtistSelected,
    required this.onSongSelected,
    this.disabled = false,
  });

  @override
  State<DualColumnSelector> createState() => _DualColumnSelectorState();
}

class _DualColumnSelectorState extends State<DualColumnSelector> {
  final ScrollController _artistScrollController = ScrollController();
  final ScrollController _songScrollController = ScrollController();

  @override
  void dispose() {
    _artistScrollController.dispose();
    _songScrollController.dispose();
    super.dispose();
  }

  List<SongItem> get _filteredSongs {
    if (widget.selectedArtist == null) return widget.songs;
    return widget.songs.where((s) => s.artist == widget.selectedArtist).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Column - Artists
        Expanded(
          child: _buildColumn(
            title: 'SANATÇI',
            items: widget.artists,
            selectedItem: widget.selectedArtist,
            onTap: (artist) {
              if (!widget.disabled) {
                HapticFeedback.lightImpact();
                widget.onArtistSelected(artist);
              }
            },
            scrollController: _artistScrollController,
            itemBuilder: (artist) => _ArtistTile(
              artist: artist,
              isSelected: artist == widget.selectedArtist,
              disabled: widget.disabled,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Right Column - Songs
        Expanded(
          child: _buildColumn(
            title: 'ŞARKI',
            items: _filteredSongs.map((s) => s.id).toList(),
            selectedItem: widget.selectedSongId,
            onTap: (songId) {
              if (!widget.disabled && widget.selectedArtist != null) {
                HapticFeedback.lightImpact();
                widget.onSongSelected(songId);
              }
            },
            scrollController: _songScrollController,
            itemBuilder: (songId) {
              final song = widget.songs.firstWhere((s) => s.id == songId);
              return _SongTile(
                song: song,
                isSelected: songId == widget.selectedSongId,
                disabled: widget.disabled || widget.selectedArtist == null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColumn<T>({
    required String title,
    required List<T> items,
    required T? selectedItem,
    required Function(T) onTap,
    required ScrollController scrollController,
    required Widget Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF394272).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF394272),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF394272),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Scrollable List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: items.isEmpty
                ? _buildEmptyState(title)
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 12,
                      endIndent: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return InkWell(
                        onTap: () => onTap(item),
                        child: itemBuilder(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String columnName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              columnName == 'SANATÇI' ? Icons.person_off : Icons.music_off,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              columnName == 'SANATÇI' 
                  ? 'Sanatçı seçin' 
                  : 'Önce sanatçı seçin',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final String artist;
  final bool isSelected;
  final bool disabled;

  const _ArtistTile({
    required this.artist,
    required this.isSelected,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFFCAB7FF).withValues(alpha: 0.15)
            : Colors.transparent,
        border: isSelected
            ? Border(
                left: BorderSide(
                  color: const Color(0xFFCAB7FF),
                  width: 3,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFCAB7FF)
                  : const Color(0xFFF5F5FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic,
              size: 16,
              color: isSelected 
                  ? Colors.white 
                  : const Color(0xFF6C6FA4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              artist,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? const Color(0xFF394272)
                    : const Color(0xFF6C6FA4),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              size: 18,
              color: Color(0xFFCAB7FF),
            ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongItem song;
  final bool isSelected;
  final bool disabled;

  const _SongTile({
    required this.song,
    required this.isSelected,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFFCAB7FF).withValues(alpha: 0.15)
            : Colors.transparent,
        border: isSelected
            ? Border(
                left: BorderSide(
                  color: const Color(0xFFCAB7FF),
                  width: 3,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFCAB7FF)
                  : disabled 
                      ? Colors.grey.shade200
                      : const Color(0xFFF5F5FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note,
              size: 16,
              color: isSelected 
                  ? Colors.white 
                  : disabled 
                      ? Colors.grey.shade400
                      : const Color(0xFF6C6FA4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              song.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? const Color(0xFF394272)
                    : disabled 
                        ? Colors.grey.shade400
                        : const Color(0xFF6C6FA4),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              size: 18,
              color: Color(0xFFCAB7FF),
            ),
        ],
      ),
    );
  }
}

/// Model for song items in the selector
class SongItem {
  final String id;
  final String artist;
  final String title;

  const SongItem({
    required this.id,
    required this.artist,
    required this.title,
  });
}
