import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../controller/card_editor_controller.dart';
import '../widgets/panel_shared.dart';
import 'social_tab_panel.dart';
import 'shapes_tab_panel.dart';
import 'arrow_tab_panel.dart';
import 'icons_tab_panel.dart';

class SymbolsToolPanel extends StatefulWidget {
  final CardEditorController controller;
  const SymbolsToolPanel({super.key, required this.controller});

  @override
  State<SymbolsToolPanel> createState() => _SymbolsToolPanelState();
}

class _SymbolsToolPanelState extends State<SymbolsToolPanel> {
  int _tabIndex = 0;
  static const _tabs = ['Social', 'Shapes', 'Arrow', 'Icons'];

  @override
  Widget build(BuildContext context) {
    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.controller.closeToolPanel,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.arrow_back, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _TabChip(
                      label: _tabs[i],
                      selected: _tabIndex == i,
                      onTap: () => setState(() => _tabIndex = i),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActiveTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_tabIndex) {
      case 0:
        return SocialTabPanel(controller: widget.controller);
      case 1:
        return ShapesTabPanel(controller: widget.controller);
      case 2:
        return ArrowTabPanel(controller: widget.controller);
      default:
        return IconsTabPanel(controller: widget.controller);
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B6B76),
          ),
        ),
      ),
    );
  }
}