import { createElement, type ReactNode } from 'react'
import type { Action, ResourceType } from './api'

export type NavItem = {
  to: string
  label: string
  exact?: boolean
  icon: ReactNode
  requiredCapability?: { resource: ResourceType; action: Action }
}

export type NavSection = {
  label: string
  items: NavItem[]
}

const Icon = (path: string) =>
  createElement(
    'svg',
    {
      className: 'h-4 w-4',
      fill: 'none',
      viewBox: '0 0 24 24',
      stroke: 'currentColor',
      strokeWidth: 1.5,
    },
    createElement('path', { strokeLinecap: 'round', strokeLinejoin: 'round', d: path })
  )

export const navSections: NavSection[] = [
  {
    label: 'NAVIGATION',
    items: [
      {
        to: '/admin',
        label: 'Dashboard',
        exact: true,
        icon: Icon(
          'M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z'
        ),
      },
      {
        to: '/admin/events',
        label: 'Event Logs',
        requiredCapability: { resource: 'EventLog', action: 'read' },
        icon: Icon('M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z'),
      },
      {
        to: '/admin/system-info',
        label: 'System Info',
        requiredCapability: { resource: 'Admin', action: 'read' },
        icon: Icon(
          'M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z'
        ),
      },
      {
        to: '/admin/users',
        label: 'Users',
        requiredCapability: { resource: 'User', action: 'read' },
        icon: Icon(
          'M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z'
        ),
      },
    ],
  },
  {
    label: 'ADMIN',
    items: [
      {
        to: '/admin/admin-accounts',
        label: 'Admin Accounts',
        requiredCapability: { resource: 'Admin', action: 'read' },
        icon: Icon(
          'M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z'
        ),
      },
      {
        to: '/admin/roles',
        label: 'Roles',
        requiredCapability: { resource: 'Admin', action: 'read' },
        icon: Icon(
          'M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z'
        ),
      },
      {
        to: '/admin/permissions',
        label: 'Permissions',
        requiredCapability: { resource: 'Admin', action: 'read' },
        icon: Icon(
          'M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z'
        ),
      },
    ],
  },
  {
    label: 'AI INFRASTRUCTURE',
    items: [
      {
        to: '/admin/llm-providers',
        label: 'LLM Providers',
        requiredCapability: { resource: 'LlmProvider', action: 'read' },
        icon: Icon(
          'M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 002.25-2.25V6.75a2.25 2.25 0 00-2.25-2.25H6.75A2.25 2.25 0 004.5 6.75v10.5a2.25 2.25 0 002.25 2.25zm.75-12h9v9h-9v-9z'
        ),
      },
      {
        to: '/admin/prompt-sets',
        label: 'Prompt Sets',
        requiredCapability: { resource: 'LlmProvider', action: 'read' },
        icon: Icon(
          'M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z'
        ),
      },
      {
        to: '/admin/suggestion-configs',
        label: 'Suggestion Configs',
        requiredCapability: { resource: 'LlmProvider', action: 'read' },
        icon: Icon(
          'M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75'
        ),
      },
    ],
  },
]
