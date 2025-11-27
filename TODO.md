# TODO: Modify AdminHomepage

- [x] Update fetchAllProducts() in product_repository.dart to order by created_at descending and limit to 2 products.
- [x] Change AdminHomepage to ConsumerStatefulWidget for Riverpod integration.
- [x] Remove logo from appBar leading.
- [x] Add logo at the top of the body.
- [x] Add state variables for products list and loading flag.
- [x] Fetch products in initState using ref.read(productRepositoryProvider).fetchAllProducts().
- [x] Replace hardcoded \_ProductTile widgets with a dynamic list of up to 2 products, showing loading indicator if needed.
- [x] Update \_ProductTile to accept a Product object, format price to Indonesian Rupiah, and display stock as quantity.
- [x] Reposition VIEW ALL button below the products, aligned to the right.
