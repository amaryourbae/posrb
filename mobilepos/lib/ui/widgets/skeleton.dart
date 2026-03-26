import 'package:flutter/material.dart';

/// A shimmering skeleton loading effect widget
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  /// Create a text skeleton with automatic sizing
  factory Skeleton.text({
    double? width,
    double height = 16,
    double borderRadius = 4,
  }) {
    return Skeleton(width: width, height: height, borderRadius: borderRadius);
  }

  /// Create a circular avatar skeleton
  factory Skeleton.circle({double size = 48}) {
    return Skeleton(width: size, height: size, isCircle: true);
  }

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A card skeleton for stats/dashboard cards
class SkeletonCard extends StatelessWidget {
  final double? height;

  const SkeletonCard({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Skeleton(width: 100, height: 12, borderRadius: 4),
          SizedBox(height: 12),
          Skeleton(width: 150, height: 24, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Product grid skeleton
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 8,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ProductCardSkeleton(),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Skeleton(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  Skeleton(width: 80, height: 16, borderRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Category list skeleton (horizontal)
class CategoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const CategoryListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Center(
            child: Skeleton(width: 60, height: 14, borderRadius: 4),
          ),
        ),
      ),
    );
  }
}

/// Table/list skeleton
class TableSkeleton extends StatelessWidget {
  final int rowCount;
  final int columnCount;

  const TableSkeleton({super.key, this.rowCount = 5, this.columnCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rowCount,
        (index) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          ),
          child: Row(
            children: List.generate(
              columnCount,
              (colIndex) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Skeleton(
                    width: colIndex == 0 ? 80 : null,
                    height: 14,
                    borderRadius: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cart item skeleton
class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Skeleton.circle(size: 48),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                Skeleton(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const Skeleton(width: 60, height: 16, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Dashboard stats skeleton
class DashboardStatsSkeleton extends StatelessWidget {
  final int count;

  const DashboardStatsSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1200
            ? 4
            : (constraints.maxWidth >= 768 ? 2 : 1);

        final itemWidth =
            (constraints.maxWidth - (24 * (crossAxisCount - 1))) /
            crossAxisCount;

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: List.generate(
            count,
            (_) => SizedBox(width: itemWidth, child: const SkeletonCard()),
          ),
        );
      },
    );
  }
}

/// Generic card skeleton
class CardSkeleton extends StatelessWidget {
  final String? title;
  const CardSkeleton({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Row(
            children: [
              Skeleton(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 100, height: 14),
                  SizedBox(height: 8),
                  Skeleton(width: 150, height: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Skeleton(width: double.infinity, height: 14),
          const SizedBox(height: 12),
          const Skeleton(width: double.infinity, height: 14),
          const SizedBox(height: 12),
          const Skeleton(width: double.infinity, height: 14),
        ],
      ),
    );
  }
}

/// Transaction table skeleton
class TransactionTableSkeleton extends StatelessWidget {
  const TransactionTableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton(width: 180, height: 20),
                Skeleton(width: 80, height: 14),
              ],
            ),
          ),
          ...List.generate(
            5,
            (index) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: const Row(
                children: [
                  Skeleton(width: 100, height: 14),
                  SizedBox(width: 24),
                  Skeleton(width: 120, height: 14),
                  SizedBox(width: 24),
                  Expanded(child: Skeleton(height: 14)),
                  SizedBox(width: 24),
                  Skeleton(width: 80, height: 24, borderRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full Dashboard Skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardStatsSkeleton(),
            const SizedBox(height: 32),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: const TransactionTableSkeleton()),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: const [
                        CardSkeleton(title: 'Shift Status'),
                        SizedBox(height: 24),
                        CardSkeleton(title: 'Alerts'),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              const CardSkeleton(title: 'Shift Status'),
              const SizedBox(height: 24),
              const CardSkeleton(title: 'Alerts'),
              const SizedBox(height: 24),
              const TransactionTableSkeleton(),
            ],
          ],
        );
      },
    );
  }
}

/// Shift history list skeleton
class ShiftHistorySkeleton extends StatelessWidget {
  final int itemCount;

  const ShiftHistorySkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const _ShiftCardSkeleton(),
    );
  }
}

class _ShiftCardSkeleton extends StatelessWidget {
  const _ShiftCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 150, height: 16),
                  SizedBox(height: 8),
                  Skeleton(width: 100, height: 14),
                ],
              ),
              Skeleton(width: 60, height: 24, borderRadius: 8),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(width: 80, height: 11),
                    SizedBox(height: 8),
                    Skeleton(width: 100, height: 14),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Skeleton(width: 80, height: 11),
                    SizedBox(height: 8),
                    Skeleton(width: 100, height: 14),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Skeleton(width: 80, height: 11),
                    SizedBox(height: 8),
                    Skeleton(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Member grid skeleton
class MemberGridSkeleton extends StatelessWidget {
  final int itemCount;

  const MemberGridSkeleton({super.key, this.itemCount = 12});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _MemberCardSkeletonV2(),
    );
  }
}

class _MemberCardSkeletonV2 extends StatelessWidget {
  const _MemberCardSkeletonV2();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Skeleton(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(width: 100, height: 14),
                    SizedBox(height: 4),
                    Skeleton(width: 80, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Skeleton(width: 60, height: 12),
              Skeleton(width: 60, height: 18, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}
