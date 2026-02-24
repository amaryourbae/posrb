<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\Ingredient;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Shift;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Throwable;

use App\Traits\ApiResponse;

class OrderController extends Controller
{
    use ApiResponse;
    /**
     * Get count of pending orders (for polling).
     * Filter Logic:
     * 1. All 'pending' payment orders (Open POS Bills)
     * 2. 'paid' but 'processing' App orders (Online Orders needing kitchen ticket/processing)
     * 3. EXCLUDE 'paid' POS orders (Dine In/Takeaway) - they are done.
     */
    public function pendingCount()
    {
        $count = Order::where(function ($query) {
                // Case 1: Payment Pending
                $query->where('payment_status', 'pending')
                      // Case 2: Paid/Processing but ONLY for Online/App orders
                      ->orWhere(function($q) {
                          $q->where('payment_status', 'paid')
                            ->where('order_status', 'processing')
                            ->whereIn('order_type', ['pickup_app', 'pickup']); // Add other online types if any
                      });
            })
            ->count();
            
            
        return $this->successResponse(['count' => $count]);
    }

    /**
     * Get list of pending orders (actions required).
     */
    public function pendingOrders()
    {
        $orders = Order::with(['items.product', 'customer'])
            ->where(function ($query) {
                $query->where('payment_status', 'pending')
                      ->orWhere(function($q) {
                          $q->where('payment_status', 'paid')
                            ->where('order_status', 'processing')
                            ->whereIn('order_type', ['pickup_app', 'pickup']);
                      });
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->successResponse($orders);
    }

    /**
     * List all orders (Admin).
     */
    public function index(Request $request)
    {
        $query = Order::with(['customer', 'items.product'])
            ->orderBy('created_at', 'desc');

        // Search by Order Number or Customer Name
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('order_number', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($q2) use ($search) {
                      $q2->where('name', 'like', "%{$search}%");
                  });
            });
        }

        // Filter by Date
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('created_at', [
                $request->start_date, 
                Carbon::parse($request->end_date)->endOfDay()
            ]);
        }

        // Filter by Status (legacy param)
        if ($request->has('status') && $request->status !== 'all') {
            $query->where('payment_status', $request->status);
        }

        // Filter by payment_status (new param)
        if ($request->has('payment_status') && $request->payment_status !== 'all') {
            $query->where('payment_status', $request->payment_status);
        }
        
        // Filter by order_status (for active/processing vs completed)
        if ($request->has('order_status') && $request->order_status !== 'all') {
             $query->where('order_status', $request->order_status);
        }

        // Clone query for stats to avoid modifying the base query for pagination
        $statsQuery = clone $query;
        $stats = [
            'total_orders' => $statsQuery->count(),
            'total_collected' => $statsQuery->sum('grand_total'),
            'total_net_sales' => $statsQuery->sum('subtotal'),
        ];

        return response()->json([
            'orders' => $query->paginate(10),
            'stats' => $stats
        ]);
    }

    /**
     * Show order details.
     */
    public function show(Order $order)
    {
        $order->load(['items.product', 'customer', 'user']);
        return response()->json($order);
    }

    public function store(Request $request)
    {
        // Validation
        $validated = $request->validate([
            'customer_id' => 'nullable|exists:customers,id',
            'customer_name' => 'nullable|string|max:255',
            'customer_phone' => 'nullable|string|max:20', 
            'order_type' => 'required|in:dine_in,takeaway,pickup_app,pickup', // Added pickup
            'payment_method' => 'required|string',
            'payment_status' => 'required|in:pending,paid,failed',
            'offline_id' => 'nullable|string|unique:orders,offline_id',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.note' => 'nullable|string',
            'items.*.modifiers' => 'nullable|array', // Allow modifiers
            'note' => 'nullable|string',
            'discount_id' => 'nullable|exists:discounts,id',
            'customer_voucher_id' => 'nullable|exists:customer_vouchers,id',
        ]);

        try {
            return DB::transaction(function () use ($validated, $request) {
                
                // 1. Initialize Financials
                $subtotal = 0;
                
                // Get Tax Rate from Settings (default 11%)
                $taxRate = \App\Models\Setting::where('key', 'tax_rate')->value('value') ?? 11;
                $discountAmount = 0;
                $voucherUsed = null;

                // Validate Customer Voucher if present
                if (!empty($validated['customer_voucher_id'])) {
                    $voucher = \App\Models\CustomerVoucher::with('reward')->lockForUpdate()->find($validated['customer_voucher_id']);
                    
                    if (!$voucher || $voucher->status !== 'active') {
                        throw new \Exception("Voucher tidak valid atau sudah digunakan");
                    }
                    if ($voucher->expires_at && $voucher->expires_at->isPast()) {
                         throw new \Exception("Voucher sudah kadaluarsa");
                    }
                    // If validated['customer_id'] provided, ensure voucher belongs to them (if member auth)
                    // The voucher check matches user_id logic if needed, but here we assume calling via customer app
                    // customer_id check:
                    if (isset($validated['customer_id']) && $voucher->customer_id != $validated['customer_id']) {
                        throw new \Exception("Voucher tidak milik akun ini");
                    }

                    $voucherUsed = $voucher;
                }
                
                // 2. Get Current Shift (Only if authenticated user exists)
                $currentShift = null;
                $userId = null;
                
                if ($request->user()) {
                    $userId = $request->user()->id;
                    $currentShift = Shift::where('user_id', $userId)
                        ->where('status', 'open')
                        ->first();
                }

                // 3. Create Order Header (Skeleton)
                $order = Order::create([
                    'order_number' => $this->generateOrderNumber(),
                    'user_id' => $userId, 
                    'shift_id' => $currentShift ? $currentShift->id : null,
                    'customer_id' => $validated['customer_id'] ?? null,
                    'customer_name' => $validated['customer_name'] ?? ($validated['customer_id'] ? Customer::find($validated['customer_id'])->name : 'Guest'),
                    'customer_phone' => $validated['customer_phone'] ?? ($validated['customer_id'] ? Customer::find($validated['customer_id'])->phone : null),
                    'order_type' => $validated['order_type'],
                    'payment_method' => $validated['payment_method'],
                    'payment_status' => $validated['payment_status'],
                    'offline_id' => $validated['offline_id'] ?? null,
                    'order_status' => $validated['payment_status'] === 'paid' ? 'processing' : 'pending',
                    'synced_at' => now(), 
                    'note' => $validated['note'] ?? null,
                ]);

                $orderItems = [];
                $voucherApplied = false;

                // 3. Process Items & Stock
                foreach ($validated['items'] as $itemData) {
                    $product = Product::with('ingredients')->findOrFail($itemData['product_id']);
                    
                    // Calculate Unit Cost (HPP) based on current ingredient costs
                    $unitCost = 0;
                    
                    if ($product->has_recipe) {
                        foreach ($product->ingredients as $ingredient) {
                            $qtyNeededPerUnit = $ingredient->pivot->quantity_needed;
                            $totalQtyNeeded = $qtyNeededPerUnit * $itemData['quantity'];
                            
                            // Stock Check
                            if ($ingredient->current_stock < $totalQtyNeeded) {
                               throw new \Exception("Insufficient stock for ingredient: {$ingredient->name}. Required: {$totalQtyNeeded}, Available: {$ingredient->current_stock}");
                            }
                            
                            // Deduct Stock
                            $ingredient->decrement('current_stock', $totalQtyNeeded);
                            
                            // HPP Calculation
                            $unitCost += $ingredient->cost_per_unit * $qtyNeededPerUnit;
                        }
                    } elseif ($product->track_stock) {
                        // Direct Product Stock Logic (e.g. Retail items)
                        if ($product->current_stock < $itemData['quantity']) {
                            throw new \Exception("Insufficient stock for product: {$product->name}. Available: {$product->current_stock}");
                        }
                        $product->decrement('current_stock', $itemData['quantity']);
                        // Helper for HPP not defined for direct products yet? usually it's cost_price column, assuming 0 for now or add column later.
                    }

                    // Calculate Unit Price including Modifiers
                    $unitPrice = $product->price;
                    if (!empty($itemData['modifiers']) && is_array($itemData['modifiers'])) {
                        foreach ($itemData['modifiers'] as $mod) {
                            $unitPrice += ($mod['price'] ?? 0);
                        }
                    }

                    $totalPrice = $unitPrice * $itemData['quantity'];
                    $subtotal += $totalPrice;
                    
                    // Check if this item is eligible for Voucher (Free Product)
                    if ($voucherUsed && !$voucherApplied && $voucherUsed->reward->type === 'free_product') {
                        // Loose check: reward->product_id matches item->product_id
                        if ($voucherUsed->reward->product_id == $product->id) {
                            // Discount = Cost of 1 Unit (including modifiers!)
                            $discountAmount += $unitPrice; 
                            $voucherApplied = true;
                        }
                    }

                    // Create OrderItem
                    $orderItems[] = new OrderItem([
                        'product_id' => $product->id,
                        'product_name' => $product->name, // Snapshot name
                        'quantity' => $itemData['quantity'],
                        'unit_price' => $unitPrice, // Updated to include modifiers
                        'unit_cost' => $unitCost, // Snapshot of HPP
                        'total_price' => $totalPrice,
                        'modifiers' => $itemData['modifiers'] ?? null, // Dynamic modifiers JSON
                        'note' => $itemData['note'] ?? null,
                    ]);
                }
                
                // Save Items
                $order->items()->saveMany($orderItems);

                // 4. Finalize Order Financials
                // Handle Normal Discount (if voucher not used, or combined? Usually one or other)
                // If voucher used, ignore discount_id or combine? Let's assume mutually exclusive for simplicity or add to discountAmount
                if (!empty($validated['discount_id']) && !$voucherUsed) {
                    $discount = \App\Models\Discount::find($validated['discount_id']);
                    if ($discount) {
                        // Validate requirement (e.g. min purchase)
                        if ($discount->min_purchase > 0 && $subtotal < $discount->min_purchase) {
                             // Skip or throw? For now just skip
                        } else {
                            if ($discount->type === 'percentage') {
                                $discountAmount += $subtotal * ($discount->value / 100);
                            } else {
                                $discountAmount += min($subtotal, $discount->value);
                            }
                            
                            // Save discount_id to order
                             $order->discount_id = $discount->id;
                        }
                    }
                }
                
                // If voucher was valid but product not found in cart
                if ($voucherUsed && !$voucherApplied) {
                    // Optional: Throw error "Product for this voucher is not in cart" or just ignore?
                    // User expectation: It should error or warn.
                     throw new \Exception("Voucher tidak dapat digunakan: Produk reward tidak ada di keranjang");
                }
                
                if ($voucherUsed && $voucherApplied) {
                     $voucherUsed->update([
                        'status' => 'used', 
                        'used_at' => now()
                    ]);
                    // Save voucher info in note or dedicated column? For now note.
                    // Or add customer_voucher_id to orders table (needs migration). I'll skip migration for now and use note/discount_amount.
                }

                $taxAmount = ($subtotal - $discountAmount) * ($taxRate / 100); 
                // Ensure non-negative
                $taxable = max(0, $subtotal - $discountAmount);
                $taxAmount = $taxable * ($taxRate / 100);
                
                $grandTotal = max(0, $subtotal + $taxAmount - $discountAmount);
                
                $order->update([
                    'subtotal' => $subtotal,
                    'tax_amount' => $taxAmount,
                    'discount_amount' => $discountAmount,
                    'grand_total' => $grandTotal,
                ]);

                // 5. Member Points Logic
                if ($order->customer_id && $order->payment_status === 'paid') {
                    Customer::where('id', $order->customer_id)->increment('points_balance', 2);
                }

                return response()->json([
                    'message' => 'Order created successfully',
                    'data' => $order->load('items'),
                ], 201);
            });
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    private function generateOrderNumber()
    {
        $date = now()->format('Ymd');
        $prefix = "TRX-{$date}-";
        
        $lastOrder = Order::where('order_number', 'like', "{$prefix}%")
                          ->orderBy('order_number', 'desc')
                          ->first();

        if ($lastOrder) {
            $sequence = (int) substr($lastOrder->order_number, -4);
            $nextSequence = str_pad($sequence + 1, 4, '0', STR_PAD_LEFT);
        } else {
            $nextSequence = '0001';
        }

        return $prefix . $nextSequence;
    }

    /**
     * Update an existing order (Resume Payment).
     */
    public function update(Request $request, Order $order)
    {
        // Prevent updating completed orders
        if ($order->payment_status === 'paid' && $request->payment_status === 'paid') {
            return response()->json(['message' => 'Order already paid'], 400); 
        }
        
        // Validation (same as store)
        $validated = $request->validate([
            'customer_id' => 'nullable|exists:customers,id',
            'customer_name' => 'nullable|string|max:255',
            'order_type' => 'required|in:dine_in,takeaway,pickup_app',
            'payment_method' => 'required|string',
            'payment_status' => 'required|in:pending,paid,failed',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.note' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($validated, $request, $order) {
            
            // 1. Revert Stock for Old Items
            foreach ($order->items as $item) {
                $product = Product::with('ingredients')->find($item->product_id);
                if ($product) {
                    foreach ($product->ingredients as $ingredient) {
                        $qtyToRestore = $ingredient->pivot->quantity_needed * $item->quantity;
                        Ingredient::where('id', $ingredient->id)->increment('current_stock', $qtyToRestore);
                    }
                }
            }
            
            // 2. Delete Old Items
            $order->items()->delete();

            // 3. Process New Items & Deduct Stock
            $subtotal = 0;
             // Get Tax Rate
            $taxRate = \App\Models\Setting::where('key', 'tax_rate')->value('value') ?? 11;
            $discountAmount = 0; 
            
            $orderItems = [];

            foreach ($validated['items'] as $itemData) {
                $product = Product::with('ingredients')->findOrFail($itemData['product_id']);
                
                $unitCost = 0;
                foreach ($product->ingredients as $ingredient) {
                    $qtyNeededPerUnit = $ingredient->pivot->quantity_needed;
                    $totalQtyNeeded = $qtyNeededPerUnit * $itemData['quantity'];
                    
                    if ($ingredient->current_stock < $totalQtyNeeded) {
                       throw new \Exception("Insufficient stock for ingredient: {$ingredient->name}");
                    }
                    
                    $ingredient->decrement('current_stock', $totalQtyNeeded);
                    $unitCost += $ingredient->cost_per_unit * $qtyNeededPerUnit;
                }

                $totalPrice = $product->price * $itemData['quantity'];
                $subtotal += $totalPrice;

                $orderItems[] = new OrderItem([
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'quantity' => $itemData['quantity'],
                    'unit_price' => $product->price,
                    'unit_cost' => $unitCost,
                    'total_price' => $totalPrice,
                    'note' => $itemData['note'] ?? null,
                ]);
            }
            
            // 4. Update Header & Save New Items
            $order->items()->saveMany($orderItems);

            $taxAmount = $subtotal * ($taxRate / 100);
            $grandTotal = $subtotal + $taxAmount - $discountAmount;
            
            // Get Current Shift (might be different from original shift)
            $currentShift = Shift::where('user_id', $request->user()->id)
                ->where('status', 'open')
                ->first();

            $order->update([
                'shift_id' => $currentShift ? $currentShift->id : $order->shift_id, // Update shift if open, else keep old
                'user_id' => $request->user()->id, // Update user to who finished it? Or keep original? Usually whoever takes payment takes credit.
                'customer_id' => $validated['customer_id'] ?? null,
                'customer_name' => $validated['customer_name'] ?? ($validated['customer_id'] ? Customer::find($validated['customer_id'])->name : 'Guest'),
                'order_type' => $validated['order_type'],
                'payment_method' => $validated['payment_method'],
                'payment_status' => $validated['payment_status'],
                'order_status' => $validated['payment_status'] === 'paid' ? 'completed' : 'pending',
                'subtotal' => $subtotal,
                'tax_amount' => $taxAmount,
                'discount_amount' => $discountAmount,
                'grand_total' => $grandTotal,
                'synced_at' => now(),
            ]);

            // 5. Member Points Logic
            if ($order->customer_id && $order->payment_status === 'paid') {
                 // 2 Points per Transaction
                 Customer::where('id', $order->customer_id)->increment('points_balance', 2);
            }

            return response()->json([
                'message' => 'Order updated successfully',
                'data' => $order->load('items'),
            ]);
        });
    }



    /**
     * Mark order as processed/completed (for paid App orders).
     */
    public function process(Order $order)
    {
        $order->update(['order_status' => 'completed']);
        return response()->json([
            'message' => 'Order marked as processed',
            'data' => $order
        ]);
    }

    /**
     * Cancel an order (requires manager PIN).
     */
    public function cancel(Request $request, Order $order)
    {
        $request->validate([
            'manager_pin' => 'required|string',
        ]);

        // Verify manager PIN
        $manager = \App\Models\User::role(['super_admin', 'store_manager'])
            ->where('pin_code', $request->manager_pin)
            ->first();

        if (!$manager) {
            return response()->json(['message' => 'Invalid manager PIN'], 403);
        }

        // Check order status
        if ($order->payment_status === 'cancelled') {
            return response()->json(['message' => 'Order already cancelled'], 400);
        }

        return DB::transaction(function () use ($order, $manager) {
            // Restore stock for each item
            foreach ($order->items as $item) {
                $product = Product::with('ingredients')->find($item->product_id);
                if ($product) {
                    foreach ($product->ingredients as $ingredient) {
                        $qtyToRestore = $ingredient->pivot->quantity_needed * $item->quantity;
                        Ingredient::where('id', $ingredient->id)
                            ->increment('current_stock', $qtyToRestore);
                    }
                }
            }

            // Update order status
            $order->update([
                'payment_status' => 'cancelled',
                'order_status' => 'cancelled',
                'note' => ($order->note ?? '') . ' | Cancelled by: ' . $manager->name,
            ]);

            return response()->json([
                'message' => 'Order cancelled successfully',
                'data' => $order,
            ]);
        });
    }

    /**
     * Refund an order (requires manager PIN).
     */
    public function refund(Request $request, Order $order)
    {
        $request->validate([
            'manager_pin' => 'required|string',
        ]);

        // Verify manager PIN
        $manager = \App\Models\User::role(['super_admin', 'store_manager'])
            ->where('pin_code', $request->manager_pin)
            ->first();

        if (!$manager) {
            return response()->json(['message' => 'Invalid manager PIN'], 403);
        }

        // Check order status
        if ($order->payment_status === 'refunded') {
            return response()->json(['message' => 'Order already refunded'], 400);
        }
        
        if ($order->payment_status !== 'paid') {
             return response()->json(['message' => 'Order is not paid, cannot refund'], 400);
        }

        return DB::transaction(function () use ($order, $manager) {
            // 1. Restore stock for each item
            foreach ($order->items as $item) {
                $product = Product::with('ingredients')->find($item->product_id);
                if ($product) {
                    foreach ($product->ingredients as $ingredient) {
                        $qtyToRestore = $ingredient->pivot->quantity_needed * $item->quantity;
                        Ingredient::where('id', $ingredient->id)
                            ->increment('current_stock', $qtyToRestore);
                    }
                }
            }

             // 2. Revert Member Points if applicable
            if ($order->customer_id) {
                 Customer::where('id', $order->customer_id)->decrement('points_balance', 2);
            }

            // 3. Update order status
            $order->update([
                'payment_status' => 'refunded',
                'order_status' => 'refunded',
                'note' => ($order->note ?? '') . ' | Refunded by: ' . $manager->name,
            ]);

            return response()->json([
                'message' => 'Order refunded successfully',
                'data' => $order,
            ]);
        });
    }
    /**
     * Send WhatsApp notification for Order Ready (Pickup).
     */
    public function notify(Request $request, Order $order)
    {
        $request->validate([
            'phone' => 'required|string',
        ]);

        $phone = $request->phone;
        
        // Construct Message
        $itemsList = $order->items->map(function ($item) {
             $productName = $item->product_name;
             $modifiers = $item->modifiers ?? [];
             
             $sizePrefix = '';
             $availablePrefix = '';

             // 1. Format Product Name (Size + Available)
             if (!empty($modifiers) && is_array($modifiers)) {
                 $sizePrefix = '';
                 $availablePrefix = '';
                 
                 foreach ($modifiers as $mod) {
                     $modName = $mod['modifier_name'] ?? $mod['name'] ?? '';
                     $optName = $mod['option_name'] ?? $mod['name'] ?? ''; 
                     
                     if ($modName === 'Available') $availablePrefix = $optName;
                     if ($modName === 'Size') $sizePrefix = $optName;
                 }

                 // Prepend Available
                 if (!empty($availablePrefix) && !str_contains($productName, $availablePrefix)) {
                     $productName = "{$availablePrefix} {$productName}";
                 }
                 // Prepend Size
                 if (!empty($sizePrefix) && !str_contains($productName, $sizePrefix)) {
                     $productName = "{$sizePrefix} {$productName}";
                 }
             }

             // Simple format for Notification
             return "{$item->quantity}x {$productName}";
        })->join("\n");

        $message = "Halo Kak *{$order->customer_name}*,\n\n" .
                   "Pesanan kamu *#{$order->order_number}* sudah siap diambil! 🥳\n\n" .
                   "Detail Pesanan:\n" .
                   "{$itemsList}\n\n" .
                   "Silakan menuju area kasir/barista untuk pengambilan.\n\n" .
                   "Terimakasih, \n" .
                   "*Ruang Bincang - Coffee & Nature*\n" .
                   "Alam Bercerita, Kopi Menyapa 🌿☕";

        // Dispatch Job
        \App\Jobs\SendWhatsAppNotification::dispatch($phone, $message);

        return response()->json(['message' => 'Notification queued successfully']);
    }

    /**
     * Validate WhatsApp Number (Proxy).
     */
    public function checkPhone(Request $request)
    {
        $request->validate(['phone' => 'required|string']);
        
        $phone = $request->phone;
        
        // 1. Check Cache (DB)
        $cached = DB::table('whatsapp_checks')->where('phone', $phone)->first();
        
        if ($cached) {
            return response()->json([
                'valid' => (bool) $cached->is_valid,
                'formatted' => $phone,
                'cached' => true // Debug info
            ]);
        }
        
        // 2. Validate via API
        $validator = new \App\Services\OneApiService();
        $isValid = $validator->validateNumber($phone);
        
        // 3. Store Result
        DB::table('whatsapp_checks')->insert([
            'phone' => $phone,
            'is_valid' => $isValid,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        
        return response()->json([
            'valid' => $isValid,
            'formatted' => $phone,
            'cached' => false
        ]);
    }
    /**
     * Send WhatsApp Receipt (Full Format).
     */
    public function sendReceipt(Request $request, Order $order)
    {
        $request->validate([
            'phone' => 'nullable|string',
        ]);

        $phone = $request->phone ?? $order->customer_phone ?? $order->customer?->phone;
        
        if (!$phone) {
            return response()->json(['message' => 'No phone number provided'], 400);
        }
        
        // Ensure phone format
        $phone = preg_replace('/\D/', '', $phone);
        if (str_starts_with($phone, '0')) {
            $phone = '62' . substr($phone, 1);
        } elseif (str_starts_with($phone, '8')) {
            $phone = '62' . $phone;
        }

        // Settings
        $settings = \App\Models\Setting::pluck('value', 'key');
        
        $storeName = $settings['store_name'] ?? 'Ruang Bincang Coffee';
        $storeAddress = $settings['store_address'] ?? '';
        $storePhone = $settings['store_phone'] ?? '';
        $storeWeb = $settings['store_website'] ?? '';
        $taxRate = $settings['tax_rate'] ?? 11;

        // Formats
        $date = Carbon::parse($order->created_at)->locale('id')->isoFormat('dddd, D MMMM Y, HH:mm');
        $shortOrder = Str::afterLast($order->order_number, '-'); // e.g. 0001
        if (empty($shortOrder)) $shortOrder = substr((string)$order->id, -4);
        
        // Message Construction
        $lines = [];
        $lines[] = "*{$storeName}*";
        if ($storeAddress) $lines[] = $storeAddress;
        if ($storePhone) $lines[] = $storePhone;
        $lines[] = "";
        $lines[] = "--------------------------------";
        $lines[] = "*{$shortOrder}*";
        $lines[] = $order->order_type === 'dine_in' ? 'Dine In' : 'Pick up Order';
        $lines[] = "Nama Customer: " . ($order->customer_name ?? 'Guest');
        $lines[] = $date;
        $lines[] = "#{$order->order_number}";
        $lines[] = "--------------------------------";
        
        $lines[] = "*Order*";
        $lines[] = "Total Order: " . $order->items->count();
        $lines[] = "";
        
        foreach ($order->items as $item) {
            $productName = $item->product_name;
            $modifiers = $item->modifiers ?? [];
            
            if (!empty($modifiers) && is_array($modifiers)) {
                  $sizePrefix = '';
                  $availablePrefix = '';
                  
                  foreach ($modifiers as $mod) {
                      $modName = trim($mod['modifier_name'] ?? $mod['name'] ?? '');
                      $optName = trim($mod['option_name'] ?? $mod['name'] ?? ''); 
                      
                      if (strcasecmp($modName, 'Available') === 0) $availablePrefix = $optName;
                      if (strcasecmp($modName, 'Size') === 0) $sizePrefix = $optName;
                  }

                  // Prepend Available
                  if (!empty($availablePrefix) && !str_contains($productName, $availablePrefix)) {
                      $productName = "{$availablePrefix} {$productName}";
                  }
                  // Prepend Size
                  if (!empty($sizePrefix) && !str_contains($productName, $sizePrefix)) {
                      $productName = "{$sizePrefix} {$productName}";
                  }
             }

             $lines[] = "{$item->quantity}x {$productName}";
             
             // Modifiers List (Filtered)
             if (!empty($modifiers) && is_array($modifiers)) {
                  $displayMods = [];
                  foreach ($modifiers as $mod) {
                      $modName = trim($mod['modifier_name'] ?? $mod['name'] ?? '');
                      $optName = trim($mod['option_name'] ?? $mod['name'] ?? '');
                      
                      if (strcasecmp($modName, 'Available') === 0 || strcasecmp($modName, 'Size') === 0) continue;
                      
                      $lowerOpt = strtolower($optName);
                      if (str_contains($lowerOpt, 'normal')) continue;
                      if (in_array($lowerOpt, ['regular', 'reguler', 'standard'])) continue;

                      if (!empty($mod['is_default'])) continue;
                      
                      $displayMods[] = $optName;
                  }
                  
                  if (!empty($displayMods)) {
                      $modString = implode(', ', $displayMods);
                      $lines[] = "   + {$modString}";
                  }
             }
             
             // Note
             if ($item->note) {
                 $lines[] = "   _\"{$item->note}\"_";
             }
             $lines[] = ""; 
         }
         
         $lines[] = "--------------------------------";
         $subtotal = number_format($order->subtotal, 0, ',', '.');
         $lines[] = "Sub Total: Rp {$subtotal}";
         
         if ($order->discount_amount > 0) {
             $discount = number_format($order->discount_amount, 0, ',', '.');
             $lines[] = "Discount: -Rp {$discount}";
         }
         
         $beforeTax = $order->grand_total - $order->tax_amount;
         $beforeTaxFmt = number_format($beforeTax, 0, ',', '.');
         $lines[] = "*SUBTOTAL: Rp {$beforeTaxFmt}*";
         
         $lines[] = "--------------------------------";
         
         $netSales = $order->subtotal - $order->discount_amount;
         $netSalesFmt = number_format($netSales, 0, ',', '.');
         $lines[] = "Net sales: Rp {$netSalesFmt}";
         
         if ($taxRate > 0) {
             $tax = number_format($order->tax_amount, 0, ',', '.');
             $lines[] = "PB1 {$taxRate}%: Rp {$tax}";
         }
        
        $lines[] = "--------------------------------";
        $grandTotal = number_format($order->grand_total, 0, ',', '.');
        $lines[] = "*Total Pembayaran: Rp {$grandTotal}*";
        $lines[] = "Metode Pembayaran: " . strtoupper(str_replace('_', ' ', $order->payment_method));
        $lines[] = "--------------------------------";
        
        $lines[] = "Terima Kasih";
        $lines[] = "*Ruang Bincang Coffee - Alam Bercerita, Kopi Menyapa*";
        if ($storeWeb) $lines[] = $storeWeb;

        $message = implode("\n", $lines);

        \App\Jobs\SendWhatsAppNotification::dispatchAfterResponse($phone, $message);

        return response()->json(['message' => 'Receipt sent successfully']);
    }
}
