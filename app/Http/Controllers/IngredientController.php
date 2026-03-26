<?php

namespace App\Http\Controllers;

use App\Models\Ingredient;
use App\Models\Unit;
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
        $query = Ingredient::with('unit')->orderBy('name');

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
            'unit_id' => 'required|exists:units,id',
            'minimum_stock_alert' => 'required|numeric|min:0',
        ]);

        $ingredient = Ingredient::create([
            'name' => $validated['name'],
            'unit_id' => $validated['unit_id'],
            'minimum_stock_alert' => $validated['minimum_stock_alert'],
            'current_stock' => 100, // Initial stock is 100 by default
            'cost_per_unit' => 0,
        ]);

        return $this->successResponse($ingredient->load('unit'), 'Ingredient created successfully', 201);
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
            'unit_id' => 'required|exists:units,id',
            'minimum_stock_alert' => 'required|numeric|min:0',
        ]);

        $ingredient->update($validated);

        return $this->successResponse($ingredient->load('unit'));
    }

    /**
     * Remove the specified ingredient.
     */
    public function destroy(Ingredient $ingredient)
    {
        $ingredient->delete();
        return $this->successResponse(null, 'Ingredient deleted successfully');
    }

    /**
     * Remove multiple ingredients.
     */
    public function bulkDelete(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:ingredients,id',
        ]);

        Ingredient::whereIn('id', $request->ids)->delete();

        return $this->successResponse(null, count($request->ids) . ' ingredients deleted successfully');
    }

    /**
     * Export CSV template for ingredients.
     */
    public function exportTemplate()
    {
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=ingredients_template.csv",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = ['Name', 'Unit', 'Minimum Stock Alert'];

        $callback = function() use($columns) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);
            
            // Add example row
            fputcsv($file, ['Coffee Beans', 'gram', '1000']);
            fputcsv($file, ['Fresh Milk', 'ml', '2000']);
            
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Import ingredients from CSV.
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
        ]);

        $file = $request->file('file');
        $path = $file->getRealPath();
        
        $handle = fopen($path, "r");
        $header = fgetcsv($handle, 1000, ","); // Skip header
        
        $count = 0;
        $errors = [];
        $rowNum = 1;

        // Cache units to avoid querying in the loop unnecessarily
        $unitsCache = Unit::all()->keyBy(function ($item) {
            return strtolower($item->abbreviation);
        });

        while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
            $rowNum++;
            if (count($data) < 3) continue;

            $name = trim($data[0]);
            $unitAbbreviation = strtolower(trim($data[1]));
            $minStock = floatval(trim($data[2]));

            if (empty($name)) {
                $errors[] = "Row $rowNum: Name is required";
                continue;
            }

            if (empty($unitAbbreviation)) {
                 $errors[] = "Row $rowNum: Unit abbreviation is required";
                 continue;
            }

            // Find or create unit
            $unit = null;
            if ($unitsCache->has($unitAbbreviation)) {
                $unit = $unitsCache->get($unitAbbreviation);
            } else {
                // If the unit doesn't exist, we can choose to create it or reject the row.
                // Creating it seems more user-friendly for "dynamic" units.
                $unitName = ucfirst($unitAbbreviation);
                if ($unitAbbreviation === 'pcs') $unitName = 'Pieces';
                if ($unitAbbreviation === 'ml') $unitName = 'Milliliter';
                
                $unit = Unit::firstOrCreate(
                    ['abbreviation' => $unitAbbreviation],
                    ['name' => $unitName]
                );
                $unitsCache->put($unitAbbreviation, $unit);
            }

            // Update or Create
            Ingredient::updateOrCreate(
                ['name' => $name],
                [
                    'unit_id' => $unit->id,
                    'minimum_stock_alert' => $minStock,
                    'current_stock' => 0, // Should be updated via Stock In normally
                    'cost_per_unit' => 0,
                ]
            );

            $count++;
        }

        fclose($handle);

        if (count($errors) > 0 && $count === 0) {
            return $this->errorResponse('Import failed', 422, $errors);
        }

        return $this->successResponse([
            'count' => $count,
            'errors' => $errors
        ], "Successfully imported $count ingredients.");
    }
}
