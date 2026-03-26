<?php

namespace App\Http\Controllers;

use App\Models\Unit;
use Illuminate\Http\Request;
use App\Traits\ApiResponse;

class UnitController extends Controller
{
    use ApiResponse;

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $units = Unit::orderBy('name', 'asc')->get();
        return $this->successResponse($units, 'Units retrieved successfully');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:units',
            'abbreviation' => 'required|string|max:10|unique:units',
        ]);

        $unit = Unit::create($validated);

        return $this->successResponse($unit, 'Unit created successfully', 201);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Unit $unit)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:units,name,' . $unit->id,
            'abbreviation' => 'required|string|max:10|unique:units,abbreviation,' . $unit->id,
        ]);

        $unit->update($validated);

        return $this->successResponse($unit, 'Unit updated successfully');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Unit $unit)
    {
        if ($unit->ingredients()->exists()) {
            return $this->errorResponse('Cannot delete unit as it is currently assigned to one or more ingredients.', 422);
        }

        Unit::destroy($unit->id);
        return $this->successResponse(null, 'Unit deleted successfully');
    }
}
