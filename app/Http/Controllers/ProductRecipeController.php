<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class ProductRecipeController extends Controller
{
    use ApiResponse;
    /**
     * Get recipe for a product.
     */
    public function index(Product $product)
    {
        return $this->successResponse($product->ingredients);
    }

    /**
     * Sync ingredients for a product.
     * Expects array: [{ ingredient_id, quantity_needed }, ...]
     */
    public function update(Request $request, Product $product)
    {
        $request->validate([
            'ingredients' => 'array',
            'ingredients.*.ingredient_id' => 'required|exists:ingredients,id',
            'ingredients.*.quantity_needed' => 'required|numeric|min:0.0001',
        ]);

        $syncData = [];
        foreach ($request->ingredients as $item) {
            $syncData[$item['ingredient_id']] = ['quantity_needed' => $item['quantity_needed']];
        }

        $product->ingredients()->sync($syncData);

        // Update product metadata if needed (e.g. has_recipe flag)
        $product->has_recipe = count($syncData) > 0;
        $product->save();

        return $this->successResponse([
            'ingredients' => $product->ingredients
        ], 'Recipe updated successfully');
    }
}
