<?php

namespace App\Http\Controllers;

use App\Models\Modifier;
use App\Models\ModifierOption;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

use App\Traits\ApiResponse;

class ModifierController extends Controller
{
    use ApiResponse;
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $modifiers = Modifier::with('options.salePrices')->orderBy('name')->get();
        return $this->successResponse($modifiers);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|in:radio,checkbox',
            'is_required' => 'boolean',
            'options' => 'required|array|min:1',
            'options.*.name' => 'required|string|max:255',
            'options.*.price' => 'numeric|min:0',
            'options.*.sale_prices' => 'nullable|array',
            'options.*.sale_prices.*.sales_type_id' => 'required|string|exists:sales_types,id',
            'options.*.sale_prices.*.price' => 'required|numeric|min:0',
        ]);

        DB::beginTransaction();
        try {
            $modifier = Modifier::create([
                'name' => $validated['name'],
                'type' => $validated['type'],
                'is_required' => $validated['is_required'] ?? false,
            ]);

            foreach ($validated['options'] as $index => $optionData) {
                $option = $modifier->options()->create([
                    'name' => $optionData['name'],
                    'price' => $optionData['price'] ?? 0,
                    'sort_order' => $index,
                ]);

                if (!empty($optionData['sale_prices'])) {
                    $prices = collect($optionData['sale_prices'])->keyBy('sales_type_id')->map(fn($p) => ['price' => $p['price']]);
                    $option->salePrices()->sync($prices);
                }
            }

            DB::commit();
            DB::commit();
            return $this->successResponse($modifier->load('options'), 'Modifier created successfully', 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Failed to create modifier', 500, $e->getMessage());
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(Modifier $modifier)
    {
        return $this->successResponse($modifier->load('options.salePrices'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Modifier $modifier)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|in:radio,checkbox',
            'is_required' => 'boolean',
            'options' => 'required|array|min:1',
            'options.*.id' => 'nullable|integer|exists:modifier_options,id',
            'options.*.name' => 'required|string|max:255',
            'options.*.price' => 'numeric|min:0',
            'options.*.sale_prices' => 'nullable|array',
            'options.*.sale_prices.*.sales_type_id' => 'required|string|exists:sales_types,id',
            'options.*.sale_prices.*.price' => 'required|numeric|min:0',
        ]);

        DB::beginTransaction();
        try {
            $modifier->update([
                'name' => $validated['name'],
                'type' => $validated['type'],
                'is_required' => $validated['is_required'] ?? false,
            ]);

            // Sync options: update existing, create new, delete removed
            $existingIds = collect($validated['options'])->pluck('id')->filter()->toArray();
            $modifier->options()->whereNotIn('id', $existingIds)->delete();

            foreach ($validated['options'] as $index => $optionData) {
                if (isset($optionData['id'])) {
                    $option = ModifierOption::find($optionData['id']);
                    $option->update([
                        'name' => $optionData['name'],
                        'price' => $optionData['price'] ?? 0,
                        'sort_order' => $index,
                    ]);
                } else {
                    $option = $modifier->options()->create([
                        'name' => $optionData['name'],
                        'price' => $optionData['price'] ?? 0,
                        'sort_order' => $index,
                    ]);
                }

                if (isset($optionData['sale_prices'])) {
                    $prices = collect($optionData['sale_prices'])->keyBy('sales_type_id')->map(fn($p) => ['price' => $p['price']]);
                    $option->salePrices()->sync($prices);
                }
            }

            DB::commit();
            DB::commit();
            return $this->successResponse($modifier->load('options'), 'Modifier updated successfully');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Failed to update modifier', 500, $e->getMessage());
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Modifier $modifier)
    {
        $modifier->delete();
        return $this->successResponse(null, 'Modifier deleted successfully');
    }
}
