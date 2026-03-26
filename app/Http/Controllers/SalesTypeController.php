<?php

namespace App\Http\Controllers;

use App\Models\SalesType;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class SalesTypeController extends Controller
{
    public function index()
    {
        return response()->json([
            'status' => 'success',
            'data' => SalesType::orderBy('sort_order', 'asc')->get()
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ]);

        if (!isset($validated['slug'])) {
            $validated['slug'] = Str::slug($validated['name'], '_');
        }

        $salesType = SalesType::create($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'Sales type created successfully',
            'data' => $salesType
        ], 201);
    }

    public function show(SalesType $salesType)
    {
        return response()->json([
            'status' => 'success',
            'data' => $salesType
        ]);
    }

    public function update(Request $request, SalesType $salesType)
    {
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ]);

        if (isset($validated['name']) && $validated['name'] !== $salesType->name) {
            $validated['slug'] = Str::slug($validated['name'], '_');
        }

        $salesType->update($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'Sales type updated successfully',
            'data' => $salesType
        ]);
    }

    public function destroy(SalesType $salesType)
    {
        // Check if there are orders using this sales type
        $orderCount = \App\Models\Order::where('sales_type_id', $salesType->id)->count();
        if ($orderCount > 0) {
            return response()->json([
                'status' => 'error',
                'message' => 'Cannot delete sales type that has existing orders. Try deactivating it instead.'
            ], 422);
        }

        $salesType->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Sales type deleted successfully'
        ]);
    }
}
