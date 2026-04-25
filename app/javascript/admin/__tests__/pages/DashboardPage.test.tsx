import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { DashboardPage } from '@admin/pages/DashboardPage'
import * as api from '@admin/lib/api'

vi.mock('@admin/lib/api', async () => {
  const actual = await vi.importActual('@admin/lib/api')
  return {
    ...actual,
    dashboardApi: {
      get: vi.fn(),
    },
    llmProvidersApi: {
      list: vi.fn(),
    },
  }
})

vi.mock('@admin/lib/sentry', () => ({
  reportTruncation: vi.fn(),
}))

vi.mock('@admin/components/StatCard', () => ({
  default: ({ label, value }: { label: string; value: number }) => (
    <div data-testid="stat-card">{label}: {value}</div>
  ),
}))

vi.mock('@admin/components/Avatar', () => ({
  default: ({ name }: { name: string }) => <div data-testid="avatar">{name}</div>,
}))

const mockDashboardGet = vi.mocked(api.dashboardApi.get)
const mockProvidersList = vi.mocked(api.llmProvidersApi.list)

const mockDashboardData: api.DashboardData = {
  status: 'ok',
  stats: {
    users_count: 10,
    roles_count: 3,
    llm_providers_count: 2,
    llm_models_count: 5,
  },
  recent_users: [
    { id: 1, name: 'Alice', email: 'alice@example.com', created_at: '2026-01-01T00:00:00Z' },
  ],
}

const mockProvider: api.LlmProvider = {
  id: 1,
  name: 'OpenAI',
  organization_id: null,
  active: true,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
}

const mockProvidersResponse: api.LlmProviderListResponse = {
  llm_providers: [mockProvider],
  meta: { page: 1, per_page: 100, total_count: 1, total_pages: 1 },
}

const renderPage = () =>
  render(
    <MemoryRouter initialEntries={['/admin']}>
      <Routes>
        <Route path="/admin" element={<DashboardPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('DashboardPage — partial failure', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows SectionError with layout=stacked when providers fetch fails', async () => {
    mockDashboardGet.mockResolvedValue(mockDashboardData)
    mockProvidersList.mockRejectedValue(new Error('503 Service Unavailable'))
    renderPage()

    await waitFor(() => {
      const alert = screen.getByRole('status')
      expect(alert).toHaveTextContent(/System Status/)
      expect(alert).toHaveAttribute('data-layout', 'stacked')
    })
    // Dashboard stats are rendered normally
    expect(screen.getAllByTestId('stat-card').length).toBeGreaterThan(0)
    // Provider list must not appear
    expect(screen.queryByText('OpenAI')).not.toBeInTheDocument()
  })

  it('shows SectionError when dashboard fetch fails', async () => {
    mockDashboardGet.mockRejectedValue(new Error('Dashboard fetch failed'))
    mockProvidersList.mockResolvedValue(mockProvidersResponse)
    renderPage()

    await waitFor(() => {
      // At least one alert should be present for the dashboard sections
      const alerts = screen.getAllByRole('status')
      expect(alerts.length).toBeGreaterThanOrEqual(1)
    })
    // Stat cards must not appear
    expect(screen.queryByTestId('stat-card')).not.toBeInTheDocument()
    // Provider section should be shown normally
    expect(screen.getByText('OpenAI')).toBeInTheDocument()
  })

  it('shows SectionErrors when both fetches fail', async () => {
    mockDashboardGet.mockRejectedValue(new Error('Network error'))
    mockProvidersList.mockRejectedValue(new Error('Network error'))
    renderPage()

    await waitFor(() => {
      const alerts = screen.getAllByRole('status')
      expect(alerts.length).toBeGreaterThanOrEqual(2)
    })
    expect(screen.queryByTestId('stat-card')).not.toBeInTheDocument()
    expect(screen.queryByText('OpenAI')).not.toBeInTheDocument()
  })
})
