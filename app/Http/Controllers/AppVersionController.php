<?php

namespace App\Http\Controllers;

use App\Models\AppVersion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Traits\ApiResponse;

class AppVersionController extends Controller
{
    use ApiResponse;

    /**
     * Get a list of all app versions (Admin).
     */
    public function index()
    {
        $versions = AppVersion::orderBy('version_code', 'desc')->get();
        return $this->successResponse($versions);
    }

    /**
     * Get the latest app version (Public/Mobile App).
     */
    public function latest()
    {
        $latest = AppVersion::orderBy('version_code', 'desc')->first();
        
        if (!$latest) {
            return $this->successResponse([
                'has_update' => false,
                'version_code' => 0,
            ], 'No versions available');
        }

        return $this->successResponse([
            'has_update' => true,
            'version_code' => $latest->version_code,
            'version_name' => $latest->version_name,
            'apk_url' => url(Storage::url($latest->apk_path)),
            'release_notes' => $latest->release_notes,
            'is_mandatory' => $latest->is_mandatory,
        ]);
    }

    /**
     * Upload a new app version (Admin).
     */
    public function store(Request $request)
    {
        $request->validate([
            'version_code' => 'required|integer|unique:app_versions,version_code',
            'version_name' => 'required|string|max:50',
            'apk_file' => 'required|file', // .apk might be seen as zip
            'release_notes' => 'nullable|string',
            'is_mandatory' => 'boolean',
        ]);

        $file = $request->file('apk_file');
        
        // Save the file to storage/app/public/apks
        $filename = 'mobilepos_v' . $request->version_code . '_' . time() . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs('apks', $filename, 'public');

        $appVersion = AppVersion::create([
            'version_code' => $request->version_code,
            'version_name' => $request->version_name,
            'apk_path' => $path,
            'release_notes' => $request->release_notes,
            'is_mandatory' => $request->is_mandatory ?? false,
        ]);

        return $this->successResponse($appVersion, 'App version uploaded successfully', 201);
    }

    /**
     * Update an app version (Admin).
     */
    public function update(Request $request, AppVersion $appVersion)
    {
        $request->validate([
            'version_code' => 'required|integer|unique:app_versions,version_code,' . $appVersion->id,
            'version_name' => 'required|string|max:50',
            'release_notes' => 'nullable|string',
            'is_mandatory' => 'boolean',
        ]);

        $appVersion->update([
            'version_code' => $request->version_code,
            'version_name' => $request->version_name,
            'release_notes' => $request->release_notes,
            'is_mandatory' => $request->is_mandatory ?? false,
        ]);

        return $this->successResponse($appVersion, 'App version updated successfully');
    }

    /**
     * Delete an app version (Admin).
     */
    public function destroy(AppVersion $appVersion)
    {
        // Delete the file from storage
        if (Storage::disk('public')->exists($appVersion->apk_path)) {
            Storage::disk('public')->delete($appVersion->apk_path);
        }

        $appVersion->delete();

        return $this->successResponse(null, 'App version deleted successfully');
    }
}
