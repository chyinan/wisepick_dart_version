import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wisepick_dart_version/features/products/jd_price_provider.dart';
import '../features/products/product_model.dart';
import '../features/products/product_detail_page.dart';

/// 商品卡片组件，用于在聊天或收藏页展示商品摘要
class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final ValueChanged<ProductModel>? onFavorite;
  final bool expandToFullWidth;
  final bool alignRight;
  final double rightReserve;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.expandToFullWidth = false,
    this.alignRight = false,
    this.rightReserve = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jdPrices = ref.watch(jdPriceCacheProvider);
    final cachedPrice = jdPrices[product.id];

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(builder: (context, constraints) {
        // 可用宽度可能很大，限制为不超过 420，且在窄屏时留出左右边距
        final double available = constraints.maxWidth.isFinite ? constraints.maxWidth : 420.0;
        final double reserved = rightReserve >= 0 ? rightReserve : 0.0;
        // 当 expandToFullWidth 为 true 时，让卡片撑满父宽度，并把右侧预留通过内部 padding 实现，
        // 这样不会因为缩小宽度而在左侧产生空白
        final double cardWidth = expandToFullWidth
            ? double.infinity
            : (available < 440 ? (available - 16).clamp(200.0, available) : 420.0);

        final EdgeInsets containerPadding = expandToFullWidth
            ? EdgeInsets.fromLTRB(12, 12, 12 + reserved, 12)
            : const EdgeInsets.all(12);

        return Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: SizedBox(
            width: cardWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              padding: containerPadding,
              child: Row(
                children: <Widget>[
                  // 左侧图片区域
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      width: 112,
                      height: 112,
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              width: 112,
                              height: 112,
                              // 在加载大图时使用 loadingBuilder 避免阻塞主视图渲染
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(color: Theme.of(context).colorScheme.surfaceVariant);
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: Theme.of(context).colorScheme.surfaceVariant);
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 右侧信息区
                  Expanded(
                    child: SizedBox(
                      height: 112,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // 标题（可换行，限制行数）
                          Text(
                            product.title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // 平台徽章（显示 PDD 等平台来源）
                          Row(
                            children: [
                              if (product.platform == 'pdd')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('PDD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              if (product.platform == 'taobao')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('TAOBAO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              if (product.platform == 'jd')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('JD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              const SizedBox(width: 6),
                            ],
                          ),
                          // 底部价格与收藏按钮
                          Row(
                            children: <Widget>[
                              Text(
                                product.platform == 'jd'
                                    ? (cachedPrice != null ? '¥${cachedPrice.toStringAsFixed(2)}' : '¥--.--')
                                    : '¥${product.price > 0 ? product.price.toStringAsFixed(2) : '价格待询'}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              // 如果宿主传入了 onFavorite 回调，显示爱心按钮；否则在购物车等场景隐藏该按钮
                              if (onFavorite != null)
                                IconButton(
                                  onPressed: () => onFavorite?.call(product),
                                  icon: const Icon(Icons.favorite_border),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

