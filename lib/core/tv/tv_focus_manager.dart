import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/platform_service.dart';

/// Gestionnaire de focus centralisé pour la navigation TV
class TVFocusManager {
  static final TVFocusManager _instance = TVFocusManager._internal();
  factory TVFocusManager() => _instance;
  TVFocusManager._internal();

  final Map<String, FocusScopeNode> _scopes = {};
  String? _currentScopeId;

  /// Enregistre un scope de focus
  void registerScope(String scopeId, FocusScopeNode scope) {
    _scopes[scopeId] = scope;
  }

  /// Supprime un scope de focus
  void unregisterScope(String scopeId) {
    _scopes.remove(scopeId);
    if (_currentScopeId == scopeId) {
      _currentScopeId = null;
    }
  }

  /// Change le scope actif
  void setActiveScope(String scopeId) {
    if (_scopes.containsKey(scopeId)) {
      _currentScopeId = scopeId;
      _scopes[scopeId]?.requestFocus();
    }
  }

  /// Obtient le scope actuel
  FocusScopeNode? get currentScope => 
      _currentScopeId != null ? _scopes[_currentScopeId] : null;
}

/// Widget wrapper pour la navigation TV avec gestion du focus
class TVFocusableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final Color? focusBorderColor;
  final double focusBorderWidth;
  final double? focusScale;
  final BorderRadius? borderRadius;
  final bool showFocusDecoration;

  const TVFocusableItem({
    Key? key,
    required this.child,
    this.onSelect,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.focusBorderColor,
    this.focusBorderWidth = 3.0,
    this.focusScale = 1.05,
    this.borderRadius,
    this.showFocusDecoration = true,
  }) : super(key: key);

  @override
  State<TVFocusableItem> createState() => _TVFocusableItemState();
}

class _TVFocusableItemState extends State<TVFocusableItem> 
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: widget.focusScale ?? 1.05,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_isFocused) {
        _animController.forward();
        HapticFeedback.selectionClick();
      } else {
        _animController.reverse();
      }
    }
  }

  void _handleSelect() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onSelect?.call();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      _handleSelect();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformService.isTVMode) {
      return GestureDetector(
        onTap: widget.onSelect,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    final focusColor = widget.focusBorderColor ?? const Color(0xFF00D4FF);

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Focus(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onKeyEvent: _handleKey,
            child: GestureDetector(
              onTap: _handleSelect,
              onLongPress: widget.onLongPress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: widget.showFocusDecoration ? BoxDecoration(
                  borderRadius: borderRadius,
                  border: _isFocused
                      ? Border.all(color: focusColor, width: widget.focusBorderWidth)
                      : null,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: focusColor.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ) : null,
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget pour créer une grille navigable TV avec gestion automatique du scroll
class TVNavigableGrid extends StatefulWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final Widget Function(BuildContext context, int index, bool isFocused, FocusNode focusNode) itemBuilder;
  final void Function(int index)? onItemFocused;
  final ScrollController? scrollController;
  final bool autofocusFirstItem;

  const TVNavigableGrid({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.65,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 20,
    this.padding = const EdgeInsets.all(16),
    this.onItemFocused,
    this.scrollController,
    this.autofocusFirstItem = true,
  }) : super(key: key);

  @override
  State<TVNavigableGrid> createState() => _TVNavigableGridState();
}

class _TVNavigableGridState extends State<TVNavigableGrid> {
  late ScrollController _scrollController;
  late List<FocusNode> _focusNodes;
  int _currentFocusIndex = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _focusNodes = List.generate(
      widget.itemCount,
      (i) => FocusNode(debugLabel: 'grid_item_$i'),
    );
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() => _onFocusChange(i));
    }
  }

  @override
  void didUpdateWidget(TVNavigableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _updateFocusNodes();
    }
  }

  void _updateFocusNodes() {
    while (_focusNodes.length < widget.itemCount) {
      final i = _focusNodes.length;
      final node = FocusNode(debugLabel: 'grid_item_$i');
      node.addListener(() => _onFocusChange(i));
      _focusNodes.add(node);
    }
    while (_focusNodes.length > widget.itemCount) {
      _focusNodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onFocusChange(int index) {
    if (_focusNodes[index].hasFocus && _currentFocusIndex != index) {
      setState(() => _currentFocusIndex = index);
      _scrollToItem(index);
      widget.onItemFocused?.call(index);
    }
  }

  void _scrollToItem(int index) {
    if (!_scrollController.hasClients) return;

    final row = index ~/ widget.crossAxisCount;
    final itemHeight = (MediaQuery.of(context).size.width - widget.padding.horizontal) /
        widget.crossAxisCount / widget.childAspectRatio;
    final targetOffset = row * (itemHeight + widget.mainAxisSpacing);

    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;

    final idealOffset = (targetOffset - viewportHeight / 3)
        .clamp(0.0, maxOffset);

    if ((idealOffset - currentOffset).abs() > 50) {
      _scrollController.animateTo(
        idealOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.childAspectRatio,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
        ),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          return FocusTraversalOrder(
            order: NumericFocusOrder(index.toDouble()),
            child: widget.itemBuilder(
              context,
              index,
              _currentFocusIndex == index,
              _focusNodes[index],
            ),
          );
        },
      ),
    );
  }
}

/// Widget pour une liste navigable TV avec support scroll automatique
class TVNavigableList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, bool isFocused, FocusNode focusNode) itemBuilder;
  final void Function(int index)? onItemFocused;
  final ScrollController? scrollController;
  final Axis scrollDirection;
  final EdgeInsets padding;
  final double itemExtent;
  final bool autofocusFirstItem;

  const TVNavigableList({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.onItemFocused,
    this.scrollController,
    this.scrollDirection = Axis.vertical,
    this.padding = EdgeInsets.zero,
    this.itemExtent = 60,
    this.autofocusFirstItem = true,
  }) : super(key: key);

  @override
  State<TVNavigableList> createState() => _TVNavigableListState();
}

class _TVNavigableListState extends State<TVNavigableList> {
  late ScrollController _scrollController;
  late List<FocusNode> _focusNodes;
  int _currentFocusIndex = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _focusNodes = List.generate(
      widget.itemCount,
      (i) => FocusNode(debugLabel: 'list_item_$i'),
    );
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() => _onFocusChange(i));
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onFocusChange(int index) {
    if (_focusNodes[index].hasFocus && _currentFocusIndex != index) {
      setState(() => _currentFocusIndex = index);
      _scrollToItem(index);
      widget.onItemFocused?.call(index);
    }
  }

  void _scrollToItem(int index) {
    if (!_scrollController.hasClients) return;

    final targetOffset = index * widget.itemExtent;
    final viewportSize = widget.scrollDirection == Axis.vertical
        ? _scrollController.position.viewportDimension
        : _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;

    final idealOffset = (targetOffset - viewportSize / 3)
        .clamp(0.0, maxOffset);

    if ((idealOffset - currentOffset).abs() > widget.itemExtent / 2) {
      _scrollController.animateTo(
        idealOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          return FocusTraversalOrder(
            order: NumericFocusOrder(index.toDouble()),
            child: widget.itemBuilder(
              context,
              index,
              _currentFocusIndex == index,
              _focusNodes[index],
            ),
          );
        },
      ),
    );
  }
}

/// Widget bouton optimisé pour TV
class TVButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? backgroundColor;
  final Color? focusColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isPrimary;

  const TVButton({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.focusColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.isPrimary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TVFocusableItem(
      focusNode: focusNode,
      autofocus: autofocus,
      onSelect: onPressed,
      focusBorderColor: focusColor ?? const Color(0xFF00D4FF),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? 
              (isPrimary ? const Color(0xFF00D4FF) : const Color(0xFF2A2A3E)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor ?? 
                    (isPrimary ? Colors.black : Colors.white),
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor ?? 
                      (isPrimary ? Colors.black : Colors.white),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
