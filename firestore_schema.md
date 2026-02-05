# Qejani Firestore Schema

## Collections

### `users`
- `uid` (string): Firebase Auth UID
- `email` (string)
- `displayName` (string)
- `role` (string): 'buyer' | 'seller' | 'admin'
- `phoneNumber` (string)
- `photoURL` (string)
- `createdAt` (timestamp)

### `sellers`
- `uid` (string): Same as user UID
- `businessName` (string)
- `mpesaNumber` (string)
- `isVerified` (boolean)
- `rating` (number)
- `reviewCount` (number)

### `products`
- `id` (string): Auto-generated
- `sellerId` (string)
- `title` (string)
- `description` (string)
- `price` (number)
- `currency` (string): 'KES'
- `category` (string)
- `images` (array of strings): URLs
- `stock` (number)
- `createdAt` (timestamp)
- `isAvailable` (boolean)

### `orders`
- `id` (string)
- `buyerId` (string)
- `sellerId` (string)
- `items` (array of objects):
  - `productId` (string)
  - `title` (string)
  - `quantity` (number)
  - `price` (number)
- `totalAmount` (number)
- `status` (string): 'pending' | 'paid' | 'shipped' | 'delivered' | 'cancelled'
- `paymentMethod` (string): 'mpesa' | 'stripe'
- `createdAt` (timestamp)

### `payments`
- `id` (string)
- `orderId` (string)
- `userId` (string)
- `amount` (number)
- `provider` (string)
- `transactionId` (string): M-Pesa Receipt or Stripe PaymentIntent ID
- `status` (string)
- `metadata` (map)

### `categories`
- `id` (string)
- `name` (string)
- `icon` (string): Asset path or URL
