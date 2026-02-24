<?php

namespace App\Http\Controllers;

use App\Models\Ingredient;
use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class IngredientController extends Controller
{
    use ApiResponse;
    /**
     * Display a listing of ingredients.
     */
    public function index(Request $request)
    {
        $query = Ingredient::orderBy('name');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('name', 'like', "%{$search}%");
        }

        return $this->successResponse($query->get());
    }

    /**
     * Store a new ingredient.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                \Illuminate\Validation\Rule::unique('ingredients')->whereNull('deleted_at'),
            ],
            'unit' => 'required|in:gram,ml,pcs',
            'minimum_stock_alert' => 'required|numeric|min:0',
        ]);

        $ingredient = Ingredient::create([
            'name' => $validated['name'],
            'unit' => $validated['unit'],
            'minimum_stock_alert' => $validated['minimum_stock_alert'],
            'current_stock' => 0, // Initial stock is 0, add via Stock In
            'cost_per_unit' => 0,
        ]);

        return $this->successResponse($ingredient, 'Ingredient created successfully', 201);
    }

    /**
     * Update the specified ingredient.
     */
    public function update(Request $request, Ingredient $ingredient)
    {
        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                \Illuminate\Validation\Rule::unique('ingredients')->ignore($ingredient->id)->whereNull('deleted_at'),
            ],
            'unit' => 'required|in:gram,ml,pcs',
            'minimum_stock_alert' => 'required|numeric|min:0',
        ]);

        $ingredient->update($validated);

        return $this->successResponse($ingredient);
    }

    /**
     * Remove the specified ingredient.
     */
    public function destroy(Ingredient $ingredient)
    {
        $ingredient->delete();
        return $this->successResponse(null, 'Ingredient deleted successfully');
    }
}
