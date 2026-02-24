<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\AuthController;

// Public Routes
Route::post('/login', [AuthController::class, 'login']);
Route::get('/app-version', [\App\Http\Controllers\Api\AppVersionController::class, 'index']);

// Storage Proxy for Local Dev (CORS Fix)
Route::get('/storage-proxy', function (Request $request) {
    $path = $request->query('path');
    if (!$path) abort(404);
    
    // Handle paths starting with /storage or not
    $relativePath = ltrim($path, '/');
    if (str_starts_with($relativePath, 'storage/')) {
        $relativePath = substr($relativePath, 8);
    }
    
    $filePath = public_path('storage/' . $relativePath);

    if (!file_exists($filePath)) {
        abort(404);
    }

    return response()->file($filePath);
});

// Public Customer App Routes
Route::prefix('public')->group(function () {
    Route::get('/categories', [\App\Http\Controllers\CategoryController::class, 'index']);
    Route::get('/products', [\App\Http\Controllers\ProductController::class, 'index']);
    Route::get('/products/{product}', [\App\Http\Controllers\ProductController::class, 'show']);
    Route::get('/promos', [\App\Http\Controllers\DiscountController::class, 'index']); // Public active promos
    Route::get('/settings', [\App\Http\Controllers\SettingController::class, 'index']); // Public store info
    Route::get('/banners', [\App\Http\Controllers\BannerController::class, 'index']); // Public Banners
    Route::get('/rewards', [\App\Http\Controllers\Api\RewardController::class, 'index']); // Public Rewards
    Route::get('/rewards/{id}', [\App\Http\Controllers\Api\RewardController::class, 'show']); // Public Reward Detail
    Route::post('/orders', [\App\Http\Controllers\OrderController::class, 'store']); // Guest Orders
    Route::get('/orders/{order}', [\App\Http\Controllers\OrderController::class, 'show']); // Public Order Status
    Route::post('/orders/validate-phone', [\App\Http\Controllers\OrderController::class, 'checkPhone']); // Public Validation

    // Member Auth
    Route::prefix('member')->group(function () {
        Route::post('/send-otp', [\App\Http\Controllers\Api\MemberAuthController::class, 'sendOtp']);
        Route::post('/check-phone', [\App\Http\Controllers\Api\MemberAuthController::class, 'checkPhoneAvailability']); // Register step 1
        Route::post('/login', [\App\Http\Controllers\Api\MemberAuthController::class, 'verifyOtp']);
        Route::post('/register', [\App\Http\Controllers\Api\MemberAuthController::class, 'verifyRegister']);
        
        Route::middleware('auth:sanctum')->group(function () {
        
            Route::post('/logout', [\App\Http\Controllers\Api\MemberAuthController::class, 'logout']);
            Route::get('/me', [\App\Http\Controllers\Api\MemberAuthController::class, 'me']);
            Route::post('/profile', [\App\Http\Controllers\Api\MemberAuthController::class, 'updateProfile']);
            Route::get('/orders', [\App\Http\Controllers\Api\MemberAuthController::class, 'orders']);
            Route::get('/orders/{id}', [\App\Http\Controllers\Api\MemberAuthController::class, 'showOrder']);

            // Loyalty Rewards
            Route::post('/rewards/{id}/redeem', [\App\Http\Controllers\Api\RewardController::class, 'redeem']);
            Route::get('/vouchers', [\App\Http\Controllers\Api\CustomerVoucherController::class, 'index']);
            Route::get('/vouchers/{id}', [\App\Http\Controllers\Api\CustomerVoucherController::class, 'show']);
        });
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']); // Add Logout here

    Route::get('/user', function (Request $request) {
        return $request->user()->load('roles'); // Load roles for frontend check
    });

    // POS Routes
    Route::post('/orders', [\App\Http\Controllers\OrderController::class, 'store']);
    Route::put('/orders/{order}', [\App\Http\Controllers\OrderController::class, 'update']);
    Route::post('/orders/{order}/whatsapp-receipt', [\App\Http\Controllers\OrderController::class, 'sendReceipt']);

    // Shared Admin/POS Routes 
    Route::middleware(['role:super_admin|store_manager|cashier'])->prefix('admin')->group(function () {
        // Catalog Read-Only
        Route::get('/categories', [\App\Http\Controllers\CategoryController::class, 'index']);
        Route::get('/products', [\App\Http\Controllers\ProductController::class, 'index']);
        Route::post('/products', [\App\Http\Controllers\ProductController::class, 'store']);
        Route::get('/products/{product}', [\App\Http\Controllers\ProductController::class, 'show']);
        Route::put('/products/{product}', [\App\Http\Controllers\ProductController::class, 'update']);
        Route::delete('/products/{product}', [\App\Http\Controllers\ProductController::class, 'destroy']);
        
        // Customer Read/Write (Cashiers can search & add)
        Route::get('/customers', [\App\Http\Controllers\CustomerController::class, 'index']);
        Route::post('/customers', [\App\Http\Controllers\CustomerController::class, 'store']);
        Route::get('/customers/{customer}', [\App\Http\Controllers\CustomerController::class, 'show']);
        Route::put('/customers/{customer}', [\App\Http\Controllers\CustomerController::class, 'update']);
        Route::delete('/customers/{customer}', [\App\Http\Controllers\CustomerController::class, 'destroy']);

        // Shift Management (Cashier needs to start/end shift)
        Route::get('/shifts/current', [\App\Http\Controllers\ShiftController::class, 'current']);
        Route::post('/shifts/start', [\App\Http\Controllers\ShiftController::class, 'start']);
        Route::post('/shifts/end', [\App\Http\Controllers\ShiftController::class, 'end']);
        Route::get('/shifts', [\App\Http\Controllers\ShiftController::class, 'index']); // History (Own for Cashier, All for Admin if filtered)

        // Dashboard Stats for POS
        Route::get('/pos/stats', [\App\Http\Controllers\DashboardController::class, 'posStats']);

        // Order History (Cashier Read Access)
        Route::get('/orders', [\App\Http\Controllers\OrderController::class, 'index']);
        Route::get('/orders/pending-count', [\App\Http\Controllers\OrderController::class, 'pendingCount']);
        Route::get('/orders/pending', [\App\Http\Controllers\OrderController::class, 'pendingOrders']);
        Route::get('/orders/{order}', [\App\Http\Controllers\OrderController::class, 'show']);

        Route::post('/orders/{order}/process', [\App\Http\Controllers\OrderController::class, 'process']);
        Route::post('/orders/{order}/cancel', [\App\Http\Controllers\OrderController::class, 'cancel']);
        Route::post('/orders/{order}/refund', [\App\Http\Controllers\OrderController::class, 'refund']);
        Route::post('/orders/{order}/notify', [\App\Http\Controllers\OrderController::class, 'notify']);
        Route::post('/orders/{order}/whatsapp-receipt', [\App\Http\Controllers\OrderController::class, 'sendReceipt']);

        // Inventory Alerts (Cashier Read Access)
        Route::get('/inventory/alerts', [\App\Http\Controllers\InventoryController::class, 'lowStockAlerts']);

        // POS Inventory Management (Read/Write)
        Route::get('/pos/inventory', [\App\Http\Controllers\PosInventoryController::class, 'index']);
        Route::put('/pos/inventory/{product}', [\App\Http\Controllers\PosInventoryController::class, 'update']);

        // Settings Update (Shared)
        Route::post('/settings', [\App\Http\Controllers\SettingController::class, 'update']);
    });

    // Admin Only Routes
    Route::middleware(['role:super_admin|store_manager'])->prefix('admin')->group(function () {
        Route::get('/dashboard', [\App\Http\Controllers\DashboardController::class, 'index']);

        

        
        // Reports
        Route::get('/reports/sales', [\App\Http\Controllers\ReportController::class, 'sales']);

        // Catalog Management (Write)
        Route::post('/categories', [\App\Http\Controllers\CategoryController::class, 'store']);
        Route::put('/categories/{category}', [\App\Http\Controllers\CategoryController::class, 'update']);
        Route::delete('/categories/{category}', [\App\Http\Controllers\CategoryController::class, 'destroy']);
        Route::get('/categories/{category}', [\App\Http\Controllers\CategoryController::class, 'show']); // details
        
        // Inventory Management
        Route::apiResource('ingredients', \App\Http\Controllers\IngredientController::class);
        Route::post('/inventory/stock-in', [\App\Http\Controllers\InventoryTransactionController::class, 'stockIn']);
        

        // Employee Management
        Route::apiResource('users', \App\Http\Controllers\UserController::class);

        // Discount Management
        Route::apiResource('discounts', \App\Http\Controllers\DiscountController::class);

        // Supplier Management
        Route::apiResource('suppliers', \App\Http\Controllers\SupplierController::class);

        // Audit Logs
        Route::get('/audit-logs', [\App\Http\Controllers\ActivityLogController::class, 'index']);

        // Product Recipe
        Route::get('/products/{product}/recipe', [\App\Http\Controllers\ProductRecipeController::class, 'index']);
        Route::post('/products/{product}/recipe', [\App\Http\Controllers\ProductRecipeController::class, 'update']);

        // Product Modifiers Assignment
        Route::post('/products/{product}/modifiers', [\App\Http\Controllers\ProductController::class, 'syncModifiers']);

        // Modifier Management
        Route::apiResource('modifiers', \App\Http\Controllers\ModifierController::class);

        // Banner Management
        Route::apiResource('banners', \App\Http\Controllers\BannerController::class);
    });

    // Public/Shared Settings (Read Only for App/POS)
    Route::get('/settings', [\App\Http\Controllers\SettingController::class, 'index']);
});
