<?php

namespace App\Http\Controllers;

use App\Models\Ingredient;
use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class InventoryController extends Controller
{
    use ApiResponse;
    /**
     * Get list of ingredients with low stock.
     */
    public function lowStockAlerts()
    {
        $alerts = Ingredient::with('unit')
            ->whereColumn('current_stock', '<=', 'minimum_stock_alert')
            ->select('id', 'name', 'current_stock', 'minimum_stock_alert', 'unit_id')
            ->get();
            
        return $this->successResponse([
            'count' => $alerts->count(),
            'data' => $alerts,
        ]);
    }
}
