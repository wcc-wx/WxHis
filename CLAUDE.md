# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

文贤HIS (Wenxian HIS) is a Vue 3 + Supabase hospital information system prototype. It's a medical application supporting outpatient, inpatient, laboratory (LIS), imaging (PACS), and electronic medical records (EMR) modules.

## Tech Stack

- **Frontend**: Vue 3 (Composition API) + Vite + TypeScript
- **State**: Pinia
- **Routing**: Vue Router with role-based access control
- **UI**: Element Plus (Chinese locale: zhCn)
- **Backend**: Supabase (PostgreSQL + Auth + Storage + RLS)

## Commands

```bash
npm run dev      # Start dev server on port 3000
npm run build    # TypeScript check + Vite build
npm run preview  # Preview production build
```

## Architecture

### Authentication Flow

Supabase Auth handles authentication. On sign-in, the `users_profile` table (joined via `auth.users.id`) stores role and employee info.

- `src/stores/auth.ts` - Auth store with role helpers (`isAdmin`, `isDoctor`, `hasRole(...)`)
- `src/composables/supabase.ts` - Supabase client singleton

### Route Guards

`src/router/index.ts` uses `beforeEach` guard to check:
1. Auth state initialized
2. Route requires auth (`meta.requiresAuth !== false`)
3. User has required role (`meta.roles`)

### Directory Structure

```
src/
├── components/
│   └── layout/MainLayout.vue    # Sidebar + header shell (authenticated)
├── composables/
│   └── supabase.ts              # Supabase client
├── router/
│   └── index.ts                 # Routes + guards + role checking
├── stores/
│   └── auth.ts                  # Auth state + role helpers
├── types/
│   └── index.ts                 # All TypeScript interfaces
├── views/                       # Lazy-loaded route components
│   ├── login/                   # Login page (unauthenticated)
│   ├── patients/                # Patient management
│   ├── registration/            # Registration/check-in
│   ├── clinic/                  # Outpatient workstation
│   ├── emr/                     # Electronic medical records
│   ├── lab/                     # LIS (lab info system)
│   ├── pacs/                    # PACS (imaging)
│   ├── pharmacy/                # Pharmacy/dispensing
│   ├── inpatient/               # Inpatient management
│   └── admin/                   # System settings (admin only)
└── main.ts                      # App entry - mounts Pinia, Router, Element Plus
```

### Role-Based Access

Roles defined in `types/index.ts`: `admin`, `doctor`, `nurse`, `lab_tech`, `radiology_tech`, `pharmacist`

Menu visibility controlled by `showMenu(roles[])` in `MainLayout.vue`, which calls `authStore.hasRole(...)`.

### Database

`supabase/schema.sql` contains all table definitions, indexes, triggers, RLS policies, and seed data.

**When modifying backend tables (e.g., adding a column, changing a constraint, updating seed data), always update `schema.sql` in the same commit.** This file is the source of truth for the database schema and must remain in sync with actual Supabase tables.

## Environment Variables

Create `.env` from `.env.example`:
```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_anon_key
```
