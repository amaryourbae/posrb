<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

use App\Traits\ApiResponse;

class ProductController extends Controller
{
    use ApiResponse;
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Product::with(['category', 'modifiers.options.salePrices', 'salePrices'])->latest();
        
        if ($request->filled('category_id')) {
            $query->where('category_id', '=', $request->category_id, 'and');
        }

        if ($request->filled('is_recommended')) {
            $query->where('is_recommended', '=', $request->boolean('is_recommended'), 'and');
        }

        if ($request->filled('is_upsell')) {
            $query->where('is_upsell', '=', $request->boolean('is_upsell'), 'and');
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%");
            });
        }

        $perPage = $request->input('per_page', 10);
        $products = $query->paginate($perPage);
        return $this->successResponse($products);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'sku' => 'required|string|unique:products,sku',
            'price' => 'required|numeric|min:0',
            'image' => 'nullable|image|max:2048',
            'description' => 'nullable|string',
            'is_upsell' => 'boolean',
            'sale_prices' => 'nullable|array',
            'sale_prices.*.sales_type_id' => 'required|exists:sales_types,id',
            'sale_prices.*.price' => 'required|numeric|min:0'
        ]);

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('products', 'public');
            $imageUrl = Storage::url($path);
        }

        $product = Product::create([
            'category_id' => $request->category_id,
            'sku' => $request->sku,
            'name' => $request->name,
            'slug' => Str::slug($request->name) . '-' . Str::random(6),
            'description' => $request->description,
            'price' => $request->price,
            'current_stock' => $request->input('current_stock', 100),
            'minimum_stock_alert' => $request->input('minimum_stock_alert', 10),
            'image_url' => $imageUrl,
            'is_available' => $request->input('is_available', true),
            'is_recommended' => $request->input('is_recommended', false),
            'is_upsell' => $request->input('is_upsell', false),
            'has_recipe' => false,
            'track_stock' => true
        ]);

        if ($request->has('sale_prices')) {
            $syncData = [];
            foreach ($request->sale_prices as $item) {
                $syncData[$item['sales_type_id']] = ['price' => $item['price']];
            }
            $product->salePrices()->sync($syncData);
        }
        
        \App\Helpers\LogHelper::log('product.created', "Created product {$product->name}", $product);

        \App\Helpers\LogHelper::log('product.created', "Created product {$product->name}", $product);

        return $this->successResponse($product, 'Product created successfully', 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Product $product)
    {
        return $this->successResponse($product->load(['category', 'modifiers.options', 'salePrices']));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Product $product)
    {
        $request->validate([
            'category_id' => 'nullable|exists:categories,id', // Allow null/empty to skip or set null
            'name' => 'string|max:255',
            'sku' => 'string|unique:products,sku,' . $product->id,
            'price' => 'numeric|min:0',
            'image' => 'nullable|image|max:2048',
            'description' => 'nullable|string',
            'is_available' => 'boolean',
            'is_recommended' => 'boolean',
            'is_upsell' => 'boolean',
            'sale_prices' => 'nullable|array',
            'sale_prices.*.sales_type_id' => 'required|exists:sales_types,id',
            'sale_prices.*.price' => 'required|numeric|min:0'
        ]);

        if ($request->hasFile('image')) {
            // Delete old image if exists
            if ($product->image_url) {
                $oldPath = str_replace('/storage/', '', $product->image_url); 
                 if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                 }
            }

            $path = $request->file('image')->store('products', 'public');
            $product->image_url = Storage::url($path);
        }

        // Mass assignment
        $data = $request->only([
            'sku', 'name', 'description', 'price', 'is_available', 'current_stock', 'minimum_stock_alert', 'is_recommended', 'is_upsell'
        ]);
        
        // Handle category_id separately to allow unsetting or updating
        if ($request->has('category_id')) {
            $data['category_id'] = $request->category_id ?: null; // Set to null if empty string
        }

        $product->fill($data);

        if ($request->has('name')) {
            $product->slug = Str::slug($request->name) . '-' . Str::random(6);
        }

        $product->save();

        if ($request->has('sale_prices')) {
            $syncData = [];
            foreach ($request->sale_prices as $item) {
                $syncData[$item['sales_type_id']] = ['price' => $item['price']];
            }
            $product->salePrices()->sync($syncData);
        }
        
        \App\Helpers\LogHelper::log('product.updated', "Updated product {$product->name}", $product);

        return response()->json($product);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Product $product)
    {
        
        // Optional: Delete image from storage
        /*
        if ($product->image_url) {
             $oldPath = str_replace('/storage/', '', $product->image_url);
             Storage::disk('public')->delete($oldPath);
        }
        */

        $name = $product->name;
        $product->delete();
        
        \App\Helpers\LogHelper::log('product.deleted', "Deleted product {$name}", null);

        return response()->json(['message' => 'Product deleted successfully']);
    }

    /**
     * Sync modifiers for a product.
     */
    public function syncModifiers(Request $request, Product $product)
    {
        \Illuminate\Support\Facades\Log::info('SyncModifiers Payload:', $request->all());
        
        if ($request->has('modifier_ids') && is_array($request->modifier_ids) && !empty($request->modifier_ids) && !is_array($request->modifier_ids[0] ?? [])) {
             // Old format simple array of IDs
             $modifierIds = $request->modifier_ids;
             $syncData = [];
             foreach ($modifierIds as $index => $modifierId) {
                $syncData[$modifierId] = ['sort_order' => $index];
             }
             $product->modifiers()->sync($syncData);
        } else {
             // New format
            $validated = $request->validate([
                'modifiers' => 'nullable|array',
                'modifiers.*.id' => 'required|exists:modifiers,id',
                'modifiers.*.condition_modifier_id' => 'nullable|exists:modifiers,id',
                'modifiers.*.condition_option_id' => 'nullable|exists:modifier_options,id',
                'modifiers.*.allowed_options' => 'nullable|array',
            ]);

            $modifiers = $validated['modifiers'] ?? [];
            
            $syncData = [];
            foreach ($modifiers as $index => $modData) {
                $syncData[$modData['id']] = [
                    'sort_order' => $index,
                    'condition_modifier_id' => $modData['condition_modifier_id'] ?? null,
                    'condition_option_id' => $modData['condition_option_id'] ?? null,
                    'allowed_options' => isset($modData['allowed_options']) ? json_encode($modData['allowed_options']) : null,
                ];
            }
            $product->modifiers()->sync($syncData);
        }
        
        return response()->json([
            'message' => 'Modifiers updated successfully',
            'modifiers' => $product->load('modifiers.options')->modifiers
        ]);
    }

    /**
     * Delete image for a product.
     */
    public function deleteImage(Product $product)
    {

        if ($product->image_url) {
            $oldPath = str_replace('/storage/', '', $product->image_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
            $product->image_url = null;
            $product->save();

            \App\Helpers\LogHelper::log('product.image_deleted', "Deleted image for product {$product->name}", $product);

            return $this->successResponse($product, 'Image deleted successfully');
        }

        return response()->json(['message' => 'No image to delete'], 404);
    }
}
