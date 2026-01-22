import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/platform_service.dart';
import 'tv_navigation_service.dart';

/// Widget global qui gere le focus et la navigation TV pour toute l'application
class TVFocusScope extends StatefulWidget {
  final Widget child;
  final bool autofocus;

  const TVFocusScope({
    Key? key,
    required this.child,
    this.autofocus = true,
  }) : super(key: key);

  @override
  State<TVFocusScope> createState() => _TVFocusScopeState();
}

class _TVFocusScopeState extends State<TVFocusScope> {
  @override
  Widget build(BuildContext context) {
    if (!PlatformService.isTVMode) {
      return widget.child;
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Navigation directionnelle
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(TraversalDirection.up),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(TraversalDirection.down),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(TraversalDirection.left),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(TraversalDirection.right),
        
        // Selection
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        
        // Retour
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.goBack): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.browserBack): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonB): const DismissIntent(),
        
        // Media controls
        LogicalKeySet(LogicalKeyboardKey.mediaPlay): const TVPlayIntent(),
        LogicalKeySet(LogicalKeyboardKey.mediaPause): const TVPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.mediaPlayPause): const TVPlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.mediaFastForward): const TVFastForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.mediaRewind): const TVRewindIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) => _handleBack(context),
          ),
        },
        child: FocusTraversalGroup(
          policy: TVFocusTraversalPolicy(),
          child: widget.child,
        ),
      ),
    );
  }

  Object? _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      HapticFeedback.lightImpact();
    }
    return null;
  }
}

/// Politique de traversee du focus optimisee pour TV
class TVFocusTraversalPolicy extends FocusTraversalPolicy {
  @override
  FocusNode? findFirstFocus(FocusNode currentNode, {bool ignoreCurrentFocus = false}) {
    return _findFirstFocusableNode(currentNode);
  }

  @override
  FocusNode findFirstFocusInDirection(FocusNode currentNode, TraversalDirection direction) {
    final nearestNode = _findNearestInDirection(currentNode, direction);
    return nearestNode ?? currentNode;
  }

  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    final sorted = descendants.toList();
    sorted.sort((a, b) {
      final rectA = _getRect(a);
      final rectB = _getRect(b);
      if (rectA == null || rectB == null) return 0;
      
      // Trier par ligne puis par colonne
      final rowDiff = (rectA.top / 100).floor() - (rectB.top / 100).floor();
      if (rowDiff != 0) return rowDiff;
      return (rectA.left - rectB.left).toInt();
    });
    return sorted;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final nextNode = _findNearestInDirection(currentNode, direction);
    if (nextNode != null && nextNode != currentNode) {
      nextNode.requestFocus();
      HapticFeedback.selectionClick();
      return true;
    }
    return false;
  }

  FocusNode? _findFirstFocusableNode(FocusNode node) {
    if (node.canRequestFocus && node.context != null) {
      return node;
    }
    for (final child in node.children) {
      final result = _findFirstFocusableNode(child);
      if (result != null) return result;
    }
    return null;
  }

  FocusNode? _findNearestInDirection(FocusNode currentNode, TraversalDirection direction) {
    final currentRect = _getRect(currentNode);
    if (currentRect == null) return null;

    FocusNode? nearest;
    double nearestDistance = double.infinity;

    void checkNode(FocusNode node) {
      if (node == currentNode || !node.canRequestFocus || node.context == null) {
        return;
      }

      final rect = _getRect(node);
      if (rect == null) return;

      final isInDirection = _isInDirection(currentRect, rect, direction);
      if (!isInDirection) return;

      final distance = _calculateDistance(currentRect, rect, direction);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = node;
      }
    }

    void traverseTree(FocusNode node) {
      checkNode(node);
      for (final child in node.children) {
        traverseTree(child);
      }
    }

    // Trouver la racine
    FocusNode root = currentNode;
    while (root.parent != null) {
      root = root.parent!;
    }

    traverseTree(root);
    return nearest;
  }

  Rect? _getRect(FocusNode node) {
    final context = node.context;
    if (context == null) return null;
    
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    
    final offset = renderObject.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, renderObject.size.width, renderObject.size.height);
  }

  bool _isInDirection(Rect current, Rect target, TraversalDirection direction) {
    const margin = 5.0;
    switch (direction) {
      case TraversalDirection.up:
        return target.bottom <= current.top + margin;
      case TraversalDirection.down:
        return target.top >= current.bottom - margin;
      case TraversalDirection.left:
        return target.right <= current.left + margin;
      case TraversalDirection.right:
        return target.left >= current.right - margin;
    }
  }

  double _calculateDistance(Rect current, Rect target, TraversalDirection direction) {
    final currentCenter = current.center;
    final targetCenter = target.center;

    // Distance principale dans la direction
    double primaryDistance;
    double secondaryDistance;

    switch (direction) {
      case TraversalDirection.up:
        primaryDistance = currentCenter.dy - targetCenter.dy;
        secondaryDistance = (currentCenter.dx - targetCenter.dx).abs();
        break;
      case TraversalDirection.down:
        primaryDistance = targetCenter.dy - currentCenter.dy;
        secondaryDistance = (currentCenter.dx - targetCenter.dx).abs();
        break;
      case TraversalDirection.left:
        primaryDistance = currentCenter.dx - targetCenter.dx;
        secondaryDistance = (currentCenter.dy - targetCenter.dy).abs();
        break;
      case TraversalDirection.right:
        primaryDistance = targetCenter.dx - currentCenter.dx;
        secondaryDistance = (currentCenter.dy - targetCenter.dy).abs();
        break;
    }

    // Penaliser les elements pas alignes
    return primaryDistance + (secondaryDistance * 0.3);
  }
}

/// Widget bouton focalisable pour TV
class TVFocusableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? focusColor;
  final double focusScale;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const TVFocusableButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.focusColor,
    this.focusScale = 1.05,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<TVFocusableButton> createState() => _TVFocusableButtonState();
}

class _TVFocusableButtonState extends State<TVFocusableButton> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.focusScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_isFocused != hasFocus) {
      setState(() => _isFocused = hasFocus);
      if (hasFocus) {
        _animationController.forward();
        HapticFeedback.selectionClick();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleActivate() {
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ?? Theme.of(context).colorScheme.primary;
    
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            _handleActivate();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  border: _isFocused
                      ? Border.all(color: focusColor, width: 3)
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
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget liste horizontale scrollable pour TV
class TVHorizontalList extends StatefulWidget {
  final List<Widget> children;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;
  final String? title;
  final Function(int)? onItemFocused;
  final Function(int)? onItemSelected;

  const TVHorizontalList({
    Key? key,
    required this.children,
    this.itemWidth = 150,
    this.itemHeight = 220,
    this.spacing = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.title,
    this.onItemFocused,
    this.onItemSelected,
  }) : super(key: key);

  @override
  State<TVHorizontalList> createState() => _TVHorizontalListState();
}

class _TVHorizontalListState extends State<TVHorizontalList> {
  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _focusNodes = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _createFocusNodes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _createFocusNodes() {
    _focusNodes.clear();
    for (int i = 0; i < widget.children.length; i++) {
      final node = FocusNode();
      node.addListener(() => _onFocusChanged(i, node));
      _focusNodes.add(node);
    }
  }

  void _onFocusChanged(int index, FocusNode node) {
    if (node.hasFocus) {
      setState(() => _currentIndex = index);
      _scrollToIndex(index);
      widget.onItemFocused?.call(index);
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    
    final targetOffset = index * (widget.itemWidth + widget.spacing);
    final viewportWidth = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    
    // Centrer l'element si possible
    final idealOffset = targetOffset - (viewportWidth / 2) + (widget.itemWidth / 2);
    final clampedOffset = idealOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    
    if ((clampedOffset - currentOffset).abs() > 10) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.length != _focusNodes.length) {
      _createFocusNodes();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: widget.padding,
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        if (widget.title != null) const SizedBox(height: 12),
        SizedBox(
          height: widget.itemHeight,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            itemCount: widget.children.length,
            separatorBuilder: (_, __) => SizedBox(width: widget.spacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: widget.itemWidth,
                child: _TVHorizontalListItem(
                  focusNode: _focusNodes[index],
                  isFocused: _currentIndex == index,
                  onSelected: () => widget.onItemSelected?.call(index),
                  child: widget.children[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TVHorizontalListItem extends StatefulWidget {
  final FocusNode focusNode;
  final bool isFocused;
  final VoidCallback? onSelected;
  final Widget child;

  const _TVHorizontalListItem({
    required this.focusNode,
    required this.isFocused,
    this.onSelected,
    required this.child,
  });

  @override
  State<_TVHorizontalListItem> createState() => _TVHorizontalListItemState();
}

class _TVHorizontalListItemState extends State<_TVHorizontalListItem> {
  bool _isLocalFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isLocalFocused != widget.focusNode.hasFocus) {
      setState(() => _isLocalFocused = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onSelected?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isLocalFocused ? 1.08 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _isLocalFocused
                ? Border.all(color: const Color(0xFF00D4FF), width: 3)
                : null,
            boxShadow: _isLocalFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
