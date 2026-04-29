import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Database,
  BookOpen,
  Settings,
  Bell,
  Search,
  Menu,
  X,
  ChevronDown,
  User,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { cn } from '@/lib/utils';

interface DashboardLayoutProps {
  children: React.ReactNode;
}

const navigation = [
  {
    name: 'Dashboard',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    name: 'Districts',
    href: '/dashboard/districts',
    icon: Database,
  },
  {
    name: 'Books',
    href: '/dashboard/books',
    icon: BookOpen,
  },
  {
    name: 'Settings',
    href: '/dashboard/settings',
    icon: Settings,
  },
];

export function DashboardLayout({ children }: DashboardLayoutProps) {
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-light font-body">
      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-dark/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 w-64 transform bg-dark text-light transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-auto',
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        )}
      >
        <div className="flex h-full flex-col">
          {/* Logo area */}
          <div className="flex h-16 items-center justify-between border-b border-light/10 px-6">
            <div className="flex items-center gap-3">
              <div className="h-8 w-8 rounded-lg bg-accent-primary flex items-center justify-center">
                <span className="font-heading text-sm font-bold text-white">F</span>
              </div>
              <span className="font-heading text-lg font-semibold text-light">
                Fazilet CMS
              </span>
            </div>
            <button
              onClick={() => setSidebarOpen(false)}
              className="lg:hidden text-light/70 hover:text-light"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
            {navigation.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                    isActive
                      ? 'bg-accent-primary text-white'
                      : 'text-light/70 hover:bg-light/10 hover:text-light'
                  )}
                >
                  <item.icon className="h-5 w-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>

          {/* Sidebar footer */}
          <div className="border-t border-light/10 p-4">
            <div className="flex items-center gap-3">
              <Avatar className="h-9 w-9">
                <AvatarFallback className="bg-accent-secondary text-white font-heading">
                  SA
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <p className="text-sm font-heading font-medium text-light">
                  Super Admin
                </p>
                <p className="text-xs text-light/50">admin@fazilet.com</p>
              </div>
            </div>
          </div>
        </div>
      </aside>

      {/* Main content area */}
      <div className="lg:pl-64">
        {/* Top header */}
        <header className="sticky top-0 z-30 flex h-16 items-center gap-4 border-b border-dark/10 bg-light px-4 sm:px-6">
          <button
            onClick={() => setSidebarOpen(true)}
            className="lg:hidden text-dark/70 hover:text-dark"
          >
            <Menu className="h-6 w-6" />
          </button>

          {/* Search bar */}
          <div className="flex-1 max-w-md">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-dark/40" />
              <Input
                type="search"
                placeholder="Search districts, books, logs..."
                className="w-full rounded-lg border-dark/10 bg-light pl-10 font-body text-dark placeholder:text-dark/40 focus-visible:ring-accent-primary"
              />
            </div>
          </div>

          <div className="flex items-center gap-3">
            {/* Notifications */}
            <Button
              variant="ghost"
              size="icon"
              className="relative text-dark/70 hover:text-dark hover:bg-dark/5"
            >
              <Bell className="h-5 w-5" />
              <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-accent-primary" />
            </Button>

            {/* User dropdown */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="ghost"
                  className="flex items-center gap-2 text-dark/70 hover:text-dark hover:bg-dark/5"
                >
                  <Avatar className="h-8 w-8">
                    <AvatarFallback className="bg-accent-secondary text-white text-xs font-heading">
                      SA
                    </AvatarFallback>
                  </Avatar>
                  <ChevronDown className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-56 font-body">
                <DropdownMenuLabel>My Account</DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem>Profile</DropdownMenuItem>
                <DropdownMenuItem>Settings</DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="text-red-600">
                  Log out
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </header>

        {/* Page content */}
        <main className="min-h-[calc(100vh-4rem)] p-4 sm:p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
