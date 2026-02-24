<?php

namespace App\Http\Controllers;

use App\Models\Ingredient;
use App\Models\InventoryTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

use App\Traits\ApiResponse;

class InventoryTransactionController extends Controller
{
    use ApiResponse;
    /**
     * Handle Stock In (Purchase).
     * Increases stock and recalculates average cost.
     */
    public function stockIn(Request $request)
    {
        $request->validate([
            'ingredient_id' => 'required|exists:ingredients,id',
            'quantity' => 'required|numeric|min:0.0001',
            'unit_cost' => 'nullable|required_without:total_cost|numeric|min:0',
            'total_cost' => 'nullable|required_without:unit_cost|numeric|min:0',
            'notes' => 'nullable|string'
        ]);

        return DB::transaction(function () use ($request) {
            $ingredient = Ingredient::lockForUpdate()->find($request->ingredient_id);

            $oldStock = $ingredient->current_stock;
            $oldCost = $ingredient->cost_per_unit;
            $inQty = $request->quantity;
            
            // Calculate Unit Cost if Total Cost is provided
            if ($request->filled('total_cost')) {
                $inCost = $request->total_cost / $inQty;
            } else {
                $inCost = $request->unit_cost;
            }

            // Calculate New Average Cost (Weighted Average)
            // Formula: ((OldStock * OldCost) + (InQty * InCost)) / (OldStock + InQty)
            // Note: If OldStock < 0 (due to overselling), treat it as 0 for cost calculation purposes to avoid skewing, 
            // OR just add the value. Let's use simple logic: Value Added = Qty * Cost.
            // New Total Value = (OldStock * OldCost) + (InQty * InCost)
            // New Cost = New Total Value / New Total Stock

            // Handle edge case where stock might be negative or zero
            $currentTotalValue = ($oldStock > 0 ? $oldStock : 0) * $oldCost;
            $incomingValue = $inQty * $inCost;
            
            $newStock = $oldStock + $inQty;
            $newTotalValue = $currentTotalValue + $incomingValue;
            
            // Avoid division by zero
            $newCostPerUnit = ($newStock > 0) ? ($newTotalValue / $newStock) : $inCost;

            // Create Transaction Record
            InventoryTransaction::create([
                'ingredient_id' => $ingredient->id,
                'type' => 'in',
                'quantity' => $inQty,
                'unit_cost' => $inCost,
                'total_cost' => $incomingValue,
                'user_id' => $request->user()->id,
                'notes' => $request->notes,
                'reference' => 'MANUAL_STOCK_IN'
            ]);

            // Update Ingredient
            $ingredient->current_stock = $newStock;
            $ingredient->cost_per_unit = $newCostPerUnit;
            $ingredient->save();

            return $this->successResponse([
                'ingredient' => $ingredient
            ], 'Stock added successfully');
        });
    }
}
