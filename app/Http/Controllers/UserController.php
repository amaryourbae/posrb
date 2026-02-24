<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

use App\Traits\ApiResponse;

class UserController extends Controller
{
    use ApiResponse;
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = User::with('roles');

        // Only hide super_admin if the current user is NOT a super_admin
        if (!$request->user()->hasRole('super_admin')) {
             $query->whereDoesntHave('roles', function ($q) {
                $q->where('name', 'super_admin');
            });
        }
            
        $query->orderBy('created_at', 'desc');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        return $this->successResponse($query->paginate(10));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'required|string|exists:roles,name',
            'pin_code' => [
                'nullable',
                'string',
                'min:4',
                'max:8',
                Rule::requiredIf($request->role === 'store_manager')
            ],
            'no_whatsapp' => 'nullable|string|max:20|unique:users',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'username' => $validated['email'], // Use email as username for now
            'password' => Hash::make($validated['password']),
            'pin_code' => !empty($validated['pin_code']) ? $validated['pin_code'] : null,
            'no_whatsapp' => !empty($validated['no_whatsapp']) ? $validated['no_whatsapp'] : null,
        ]);

        $user->assignRole($validated['role']);
        
        \App\Helpers\LogHelper::log('user.created', "Created user {$user->name} as {$validated['role']}", $user);

        return $this->successResponse([
            'data' => $user->load('roles')
        ], 'User created successfully', 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(User $user)
    {
        return $this->successResponse($user->load('roles'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => ['required', 'email', Rule::unique('users')->ignore($user->id)],
            'password' => 'nullable|string|min:6',
            'role' => 'required|string|exists:roles,name',
            'pin_code' => [
                'nullable',
                'string',
                'min:4',
                'max:8',
                Rule::requiredIf($request->role === 'store_manager')
            ],
            'no_whatsapp' => ['nullable', 'string', 'max:20', Rule::unique('users')->ignore($user->id)],
        ]);

        $user->name = $validated['name'];
        $user->email = $validated['email'];
        if (!empty($validated['password'])) {
            $user->password = Hash::make($validated['password']);
        }
        
        $user->pin_code = !empty($validated['pin_code']) ? $validated['pin_code'] : null;
        $user->no_whatsapp = !empty($validated['no_whatsapp']) ? $validated['no_whatsapp'] : null;

        $user->save();

        $user->syncRoles([$validated['role']]);
        
        \App\Helpers\LogHelper::log('user.updated', "Updated user {$user->name}", $user);

        return $this->successResponse([
            'data' => $user->load('roles')
        ], 'User updated successfully');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $user)
    {
        if ($user->hasRole('super_admin')) {
            return $this->errorResponse('Cannot delete super admin', 403);
        }
        
        $userName = $user->name;
        $user->delete();
        
        \App\Helpers\LogHelper::log('user.deleted', "Deleted user {$userName}", null); // Pass null as subject since it's deleted

        return $this->successResponse(null, 'User deleted successfully');
    }
}
