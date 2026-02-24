<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class BannerController extends Controller
{
    use ApiResponse;
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $banners = \App\Models\Banner::orderBy('order', 'asc')->orderBy('created_at', 'desc')->get();
        return $this->successResponse($banners);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:2048', // Max 2MB
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'action_label' => 'nullable|string|max:50',
            'action_link' => 'nullable|string|max:255',
            'order' => 'nullable|integer',
            'is_active' => 'boolean'
        ]);

        $input = $request->except('image');
        
        // Handle File Upload
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('banners', 'public');
            $input['image_url'] = \Illuminate\Support\Facades\Storage::url($path);
        }

        $banner = \App\Models\Banner::create($input);

        return $this->successResponse($banner, 'Banner created successfully', 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        return $this->successResponse(\App\Models\Banner::findOrFail($id));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
         $request->validate([
            'image' => 'nullable|image|max:2048', 
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'action_label' => 'nullable|string|max:50',
            'action_link' => 'nullable|string|max:255',
            'order' => 'nullable|integer',
            'is_active' => 'boolean'
        ]);

        $banner = \App\Models\Banner::findOrFail($id);
        $input = $request->except('image');

        if ($request->hasFile('image')) {
            // Delete old image if exists (optional, good practice)
            // Storage::disk('public')->delete(str_replace('/storage/', '', $banner->image_url));

            $path = $request->file('image')->store('banners', 'public');
            $input['image_url'] = \Illuminate\Support\Facades\Storage::url($path);
        }

        $banner->update($input);

        return $this->successResponse($banner);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $banner = \App\Models\Banner::findOrFail($id);
        $banner->delete();
        return $this->successResponse(null, 'Banner deleted');
    }
}
