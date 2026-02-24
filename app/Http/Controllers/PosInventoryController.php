<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class PosInventoryController extends Controller
{
    use ApiResponse;
    /**
     * Display a listing of products with inventory info.
     */
    public function index(Request $request)
    {
        $query = Product::select('id', 'name', 'sku', 'image_url', 'current_stock', 'minimum_stock_alert', 'price', 'is_available')
            ->latest();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%");
            });
        }
        
        if ($request->has('low_stock')) {
             $query->whereColumn('current_stock', '<=', 'minimum_stock_alert');
        }

        $perPage = $request->input('per_page', 24);
        return $this->successResponse($query->paginate($perPage));
    }

    /**
     * Update stock for a product.
     */
    public function update(Request $request, Product $product)
    {
        $validated = $request->validate([
            'current_stock' => 'required|numeric|min:0',
            'minimum_stock_alert' => 'nullable|numeric|min:0',
            'is_available' => 'boolean',
            'reason' => 'nullable|string' // e.g., "Restock", "Correction"
        ]);

        $oldStock = $product->current_stock;
        $newStock = $validated['current_stock'];
        
        $product->current_stock = $newStock;
        
        if (isset($validated['minimum_stock_alert'])) {
            $product->minimum_stock_alert = $validated['minimum_stock_alert'];
        }
        
        if (isset($validated['is_available'])) {
             $product->is_available = $validated['is_available'];
        }

        $product->save();

        // Optional: Log stock change
        if ($oldStock != $newStock) {
             $diff = $newStock - $oldStock;
             $action = $diff > 0 ? "Added +{$diff}" : "Deducted {$diff}";
             \App\Helpers\LogHelper::log('inventory.update', "{$action} stock for {$product->name}. Reason: " . ($validated['reason'] ?? 'Manual Update'), $product);
        }

        return $this->successResponse($product, 'Inventory updated successfully');
    }
}
