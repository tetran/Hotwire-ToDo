import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { LlmProviderWorkspacePage } from '@admin/pages/llm-providers/LlmProviderWorkspacePage'
import * as api from '@admin/lib/api'

vi.mock('@admin/lib/api', async () => {
  const actual = await vi.importActual('@admin/lib/api')
  return {
    ...actual,
    llmProvidersApi: {
      get: vi.fn(),
    },
    llmModelsApi: {
      list: vi.fn(),
      delete: vi.fn(),
    },
  }
})

vi.mock('@admin/lib/sentry', () => ({
  reportTruncation: vi.fn(),
}))

const mockGet = vi.mocked(api.llmProvidersApi.get)
const mockList = vi.mocked(api.llmModelsApi.list)
const mockDelete = vi.mocked(api.llmModelsApi.delete)

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

const mockProvider: api.LlmProvider = {
  id: 1,
  name: 'OpenAI',
  organization_id: 'org-123',
  active: true,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
  llm_models_count: 2,
}

const mockModel: api.LlmModel = {
  id: 10,
  llm_provider_id: 1,
  name: 'gpt-4o',
  display_name: 'GPT-4o',
  active: true,
  default_model: true,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
}

const mockModelsResponse: api.LlmModelListResponse = {
  llm_models: [mockModel],
}

const renderPage = (initialPath = '/admin/llm-providers/1') =>
  render(
    <MemoryRouter initialEntries={[initialPath]}>
      <Routes>
        <Route path="/admin/llm-providers/:id" element={<LlmProviderWorkspacePage />} />
      </Routes>
    </MemoryRouter>
  )

describe('LlmProviderWorkspacePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGet.mockResolvedValue(mockProvider)
    mockList.mockResolvedValue(mockModelsResponse)
  })

  it('renders loading state initially', () => {
    mockGet.mockReturnValue(new Promise(() => {}))
    mockList.mockReturnValue(new Promise(() => {}))
    renderPage()
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders provider info and models after load', async () => {
    renderPage()
    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /LLM Provider: OpenAI/ })).toBeInTheDocument()
    })
    expect(screen.getByText('API Key')).toBeInTheDocument()
    expect(screen.getByText('gpt-4o')).toBeInTheDocument()
    expect(screen.getByText('GPT-4o')).toBeInTheDocument()
  })

  it('renders back link and provider edit button', async () => {
    renderPage()
    await waitFor(() => {
      expect(screen.getByRole('link', { name: 'Back to LLM Providers' })).toBeInTheDocument()
    })
    expect(screen.getByTestId('workspace-provider-edit')).toBeInTheDocument()
  })

  it('renders flash banner from location state and clears it', async () => {
    render(
      <MemoryRouter initialEntries={[{ pathname: '/admin/llm-providers/1', state: { flash: 'Provider updated' } }]}>
        <Routes>
          <Route path="/admin/llm-providers/:id" element={<LlmProviderWorkspacePage />} />
        </Routes>
      </MemoryRouter>
    )
    await waitFor(() => {
      expect(screen.getByText('Provider updated')).toBeInTheDocument()
    })
    // navigate called to clear state
    expect(mockNavigate).toHaveBeenCalledWith('/admin/llm-providers/1', { replace: true, state: null })
  })

  it('calls delete and refreshes models', async () => {
    mockDelete.mockResolvedValue(undefined)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('gpt-4o')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { name: 'Delete' }))

    await waitFor(() => {
      expect(mockDelete).toHaveBeenCalledWith(1, 10)
    })
  })

  it('shows error when fetch fails', async () => {
    mockGet.mockRejectedValue(new Error('Network error'))
    mockList.mockRejectedValue(new Error('Network error'))
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Network error')).toBeInTheDocument()
    })
  })

  it('clears stale error message when a successful re-fetch follows a delete failure', async () => {
    mockDelete.mockRejectedValueOnce(new Error('Delete failed'))
    mockDelete.mockResolvedValueOnce(undefined)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('gpt-4o')).toBeInTheDocument()
    })

    // First click: delete fails → stale error is shown
    fireEvent.click(screen.getByRole('button', { name: 'Delete' }))
    await waitFor(() => {
      expect(screen.getByText('Delete failed')).toBeInTheDocument()
    })

    // Second click: delete succeeds → refreshKey++ triggers re-fetch
    fireEvent.click(screen.getByRole('button', { name: 'Delete' }))
    await waitFor(() => {
      expect(mockDelete).toHaveBeenCalledTimes(2)
    })

    // Stale error must be cleared after the successful re-fetch
    await waitFor(() => {
      expect(screen.queryByText('Delete failed')).not.toBeInTheDocument()
    })
  })
})
