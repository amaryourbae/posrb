<?php

namespace App\Http\Controllers;

use App\Models\Supplier;
use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class SupplierController extends Controller
{
    use ApiResponse;
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Supplier::orderBy('created_at', 'desc');

        if ($request->has('search')) {
            $query->where('name', 'like', "%{$request->search}%", 'and')
                  ->orWhere('contact_person', 'like', "%{$request->search}%");
        }

        return $this->successResponse($query->paginate(10));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'contact_person' => 'nullable|string',
            'phone' => 'nullable|string',
            'email' => 'nullable|email',
            'address' => 'nullable|string',
            'note' => 'nullable|string',
        ]);

        $supplier = Supplier::create($validated);
        
        \App\Helpers\LogHelper::log('supplier.created', "Created supplier {$supplier->name}", $supplier);

        return $this->successResponse($supplier, 'Supplier created successfully', 201);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Supplier $supplier)
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'contact_person' => 'nullable|string',
            'phone' => 'nullable|string',
            'email' => 'nullable|email',
            'address' => 'nullable|string',
            'note' => 'nullable|string',
        ]);

        $supplier->update($validated);
        
        \App\Helpers\LogHelper::log('supplier.updated', "Updated supplier {$supplier->name}", $supplier);

        return $this->successResponse($supplier);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Supplier $supplier)
    {
        $name = $supplier->name;
        Supplier::destroy($supplier->id);
        \App\Helpers\LogHelper::log('supplier.deleted', "Deleted supplier {$name}", null);
        
        return $this->successResponse(null, 'Supplier deleted');
    }
}
