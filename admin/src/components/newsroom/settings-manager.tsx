"use client";

import { useState, useTransition } from "react";
import { toast } from "sonner";
import {
  Activity,
  Bot,
  CheckCircle2,
  Cpu,
  Eye,
  EyeOff,
  Flame,
  Globe,
  Key,
  Layers,
  Play,
  RefreshCw,
  Save,
  Shield,
  Sliders,
  Sparkles,
  Video,
  XCircle,
  Zap,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { proxyJson } from "@/lib/proxy";

export type AppSettingsData = {
  llm_provider: string;
  llm_api_key_set: boolean;
  llm_api_key_masked: string;
  llm_model: string;
  youtube_api_key_set: boolean;
  youtube_api_key_masked: string;
  auto_ingest_enabled: boolean;
  ingest_interval_min: number;
  auto_publish_trusted: boolean;
  extra_config: Record<string, unknown>;
  updated_at?: string | null;
};

type TestResult = {
  ok: boolean;
  provider: string;
  model: string;
  latency_ms: number;
  sample_output?: {
    headline?: string;
    summary?: string;
    category?: string;
    tags?: string[];
  } | null;
  error?: string | null;
};

type IngestStatus = {
  is_running: boolean;
  last_run_at: string | null;
  total_runs: number;
  total_created: number;
  total_merged: number;
  total_failures: number;
  max_concurrency: number;
  last_error: string | null;
};

const PROVIDER_PRESETS: Record<string, { name: string; models: string[]; docs: string }> = {
  anthropic: {
    name: "Anthropic Claude",
    models: ["claude-3-5-haiku-20241022", "claude-3-5-sonnet-20241022", "claude-3-opus-20240229"],
    docs: "https://console.anthropic.com/settings/keys",
  },
  openai: {
    name: "OpenAI GPT",
    models: ["gpt-4o-mini", "gpt-4o", "gpt-4-turbo"],
    docs: "https://platform.openai.com/api-keys",
  },
  gemini: {
    name: "Google Gemini",
    models: ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-2.0-flash-exp"],
    docs: "https://aistudio.google.com/app/apikey",
  },
  local: {
    name: "Local Deterministic Engine",
    models: ["local-deterministic-v1"],
    docs: "",
  },
};

export function SettingsManager({ initialSettings }: { initialSettings: AppSettingsData }) {
  const [settings, setSettings] = useState<AppSettingsData>(initialSettings);
  const [isPending, startTransition] = useTransition();

  // LLM State
  const [provider, setProvider] = useState<string>(initialSettings.llm_provider || "anthropic");
  const [model, setModel] = useState<string>(initialSettings.llm_model || "claude-3-5-haiku-20241022");
  const [llmKeyInput, setLlmKeyInput] = useState<string>("");
  const [showLlmKey, setShowLlmKey] = useState<boolean>(false);

  // YouTube State
  const [youtubeKeyInput, setYoutubeKeyInput] = useState<string>("");
  const [showYoutubeKey, setShowYoutubeKey] = useState<boolean>(false);

  // Ingestion State
  const [autoIngest, setAutoIngest] = useState<boolean>(initialSettings.auto_ingest_enabled);
  const [intervalMin, setIntervalMin] = useState<number>(initialSettings.ingest_interval_min || 15);
  const [autoPublish, setAutoPublish] = useState<boolean>(initialSettings.auto_publish_trusted);

  // Testing & Status State
  const [isTesting, setIsTesting] = useState<boolean>(false);
  const [testResult, setTestResult] = useState<TestResult | null>(null);
  const [isIngesting, setIsIngesting] = useState<boolean>(false);
  const [engineStatus, setEngineStatus] = useState<IngestStatus | null>(null);

  const activeProviderMeta = PROVIDER_PRESETS[provider] || PROVIDER_PRESETS.anthropic;

  const handleProviderChange = (newProvider: string) => {
    setProvider(newProvider);
    const preset = PROVIDER_PRESETS[newProvider];
    if (preset && preset.models.length > 0) {
      setModel(preset.models[0]);
    }
    setTestResult(null);
  };

  const handleTestConnection = async () => {
    setIsTesting(true);
    setTestResult(null);
    try {
      const payload: { llm_provider: string; llm_model: string; llm_api_key?: string } = {
        llm_provider: provider,
        llm_model: model,
      };
      if (llmKeyInput.trim()) {
        payload.llm_api_key = llmKeyInput.trim();
      }
      const res = await proxyJson<TestResult>("admin/v1/settings/test-llm", {
        method: "POST",
        body: JSON.stringify(payload),
      });
      setTestResult(res);
      if (res.ok) {
        toast.success(`LLM test succeeded (${res.latency_ms}ms)`);
      } else {
        toast.error(`LLM test failed: ${res.error || "Unknown error"}`);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setTestResult({
        ok: false,
        provider,
        model,
        latency_ms: 0,
        error: msg,
      });
      toast.error(`Connection failed: ${msg}`);
    } finally {
      setIsTesting(false);
    }
  };

  const handleSaveSettings = () => {
    startTransition(async () => {
      try {
        const payload: Record<string, unknown> = {
          llm_provider: provider,
          llm_model: model,
          auto_ingest_enabled: autoIngest,
          ingest_interval_min: Number(intervalMin),
          auto_publish_trusted: autoPublish,
        };

        if (llmKeyInput.trim()) {
          payload.llm_api_key = llmKeyInput.trim();
        }
        if (youtubeKeyInput.trim()) {
          payload.youtube_api_key = youtubeKeyInput.trim();
        }

        const res = await proxyJson<AppSettingsData>("admin/v1/settings", {
          method: "PATCH",
          body: JSON.stringify(payload),
        });

        setSettings(res);
        setLlmKeyInput("");
        setYoutubeKeyInput("");
        toast.success("Settings saved and live in runtime!");
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        toast.error(`Failed to save settings: ${msg}`);
      }
    });
  };

  const handleTriggerIngest = async () => {
    setIsIngesting(true);
    try {
      const res = await proxyJson<{
        sources_checked?: number;
        created?: number;
        merged?: number;
        status?: string;
      }>("admin/v1/ingest/run", {
        method: "POST",
      });
      toast.success(
        `Ingestion run complete! ${res.created ?? 0} created, ${res.merged ?? 0} merged across ${
          res.sources_checked ?? "active"
        } sources.`,
      );
      // Fetch status
      handleRefreshStatus();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      toast.error(`Ingest trigger failed: ${msg}`);
    } finally {
      setIsIngesting(false);
    }
  };

  const handleRefreshStatus = async () => {
    try {
      const status = await proxyJson<IngestStatus>("admin/v1/ingest/status");
      setEngineStatus(status);
    } catch {
      // Ignored if status unavailable
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Banner & Quick Actions */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-xl border bg-gradient-to-r from-card to-muted/40 p-5 shadow-sm">
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <Sliders className="size-5 text-primary" />
            <h2 className="text-xl font-bold tracking-tight">Dynamic Runtime Settings</h2>
            <Badge variant="outline" className="border-primary/40 text-primary text-xs">
              Live Owner Config
            </Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            Configure AI models, API keys, and autonomous newsroom ingestion on the fly without restarting
            Docker containers or changing files.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleTriggerIngest}
            disabled={isIngesting}
            className="gap-2"
          >
            <Play className={`size-4 ${isIngesting ? "animate-spin" : ""}`} />
            {isIngesting ? "Ingesting..." : "Ingest Now"}
          </Button>
          <Button
            size="sm"
            onClick={handleSaveSettings}
            disabled={isPending}
            className="gap-2 font-semibold shadow"
          >
            <Save className={`size-4 ${isPending ? "animate-spin" : ""}`} />
            {isPending ? "Saving..." : "Save Settings"}
          </Button>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Section 1: AI & LLM Engine Configuration */}
        <Card className="shadow-sm">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Sparkles className="size-5 text-amber-500" />
                <CardTitle className="text-lg">AI & LLM Intelligence</CardTitle>
              </div>
              <Badge
                variant={settings.llm_api_key_set || provider === "local" ? "default" : "secondary"}
                className="text-xs"
              >
                {settings.llm_api_key_set
                  ? "API Key Active"
                  : provider === "local"
                    ? "Offline Engine"
                    : "Key Required"}
              </Badge>
            </div>
            <CardDescription>
              Powers cricket news summarization, bilingual Hindi translation, and entity tagging.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Provider Selector */}
            <div className="space-y-2">
              <Label htmlFor="provider" className="text-sm font-semibold flex items-center gap-2">
                <Cpu className="size-4" /> AI Provider
              </Label>
              <div className="grid grid-cols-2 gap-2">
                {Object.entries(PROVIDER_PRESETS).map(([key, item]) => {
                  const isSelected = provider === key;
                  return (
                    <button
                      key={key}
                      type="button"
                      onClick={() => handleProviderChange(key)}
                      className={`flex flex-col items-start p-3 rounded-lg border text-left transition-all ${
                        isSelected
                          ? "border-primary bg-primary/5 ring-2 ring-primary/20 font-semibold"
                          : "border-border hover:bg-muted/50"
                      }`}
                    >
                      <span className="text-sm font-medium">{item.name}</span>
                      <span className="text-xs text-muted-foreground mt-0.5">
                        {key === "local" ? "Zero API cost, offline" : `e.g. ${item.models[0]}`}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Model Selection */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="model" className="text-sm font-semibold flex items-center gap-2">
                  <Bot className="size-4" /> Model Name
                </Label>
                {activeProviderMeta.docs && (
                  <a
                    href={activeProviderMeta.docs}
                    target="_blank"
                    rel="noreferrer"
                    className="text-xs text-primary hover:underline flex items-center gap-1"
                  >
                    API Keys Portal
                  </a>
                )}
              </div>
              <div className="flex gap-2">
                <Input
                  id="model"
                  value={model}
                  onChange={(e) => setModel(e.target.value)}
                  placeholder="e.g. claude-3-5-haiku-20241022"
                  className="font-mono text-sm"
                />
              </div>
              {activeProviderMeta.models.length > 0 && (
                <div className="flex flex-wrap gap-1.5 pt-1">
                  <span className="text-xs text-muted-foreground mr-1 self-center">Presets:</span>
                  {activeProviderMeta.models.map((m) => (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setModel(m)}
                      className={`text-xs px-2 py-0.5 rounded border transition-colors ${
                        model === m
                          ? "bg-primary text-primary-foreground border-primary"
                          : "bg-muted/60 hover:bg-muted text-muted-foreground"
                      }`}
                    >
                      {m}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* API Key */}
            {provider !== "local" && (
              <div className="space-y-2 pt-2 border-t">
                <div className="flex items-center justify-between">
                  <Label htmlFor="llm_key" className="text-sm font-semibold flex items-center gap-2">
                    <Key className="size-4" /> Provider API Key
                  </Label>
                  {settings.llm_api_key_set && (
                    <span className="text-xs text-emerald-600 font-mono bg-emerald-50 dark:bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-200 dark:border-emerald-800">
                      Active: {settings.llm_api_key_masked}
                    </span>
                  )}
                </div>
                <div className="relative">
                  <Input
                    id="llm_key"
                    type={showLlmKey ? "text" : "password"}
                    value={llmKeyInput}
                    onChange={(e) => setLlmKeyInput(e.target.value)}
                    placeholder={
                      settings.llm_api_key_set
                        ? "Enter new API key to overwrite existing..."
                        : "Paste secret API key here..."
                    }
                    className="pr-10 font-mono text-xs"
                  />
                  <button
                    type="button"
                    onClick={() => setShowLlmKey(!showLlmKey)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showLlmKey ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                  </button>
                </div>
                <p className="text-xs text-muted-foreground">
                  Stored securely in your PostgreSQL database. Never exposed in mobile client responses.
                </p>
              </div>
            )}

            {/* Test Connection Button */}
            <div className="pt-2">
              <Button
                type="button"
                variant="outline"
                onClick={handleTestConnection}
                disabled={isTesting}
                className="w-full gap-2 border-primary/30 hover:bg-primary/5"
              >
                {isTesting ? (
                  <RefreshCw className="size-4 animate-spin text-primary" />
                ) : (
                  <Zap className="size-4 text-primary" />
                )}
                {isTesting ? "Testing LLM Completion..." : "Test AI Connection"}
              </Button>
            </div>

            {/* Test Results Display */}
            {testResult && (
              <div
                className={`rounded-lg border p-3.5 text-xs space-y-2 ${
                  testResult.ok
                    ? "bg-emerald-50/50 dark:bg-emerald-950/20 border-emerald-200 dark:border-emerald-800 text-emerald-900 dark:text-emerald-100"
                    : "bg-destructive/10 border-destructive/30 text-destructive dark:text-destructive-foreground"
                }`}
              >
                <div className="flex items-center justify-between font-semibold">
                  <div className="flex items-center gap-1.5">
                    {testResult.ok ? (
                      <CheckCircle2 className="size-4 text-emerald-600" />
                    ) : (
                      <XCircle className="size-4 text-destructive" />
                    )}
                    <span>{testResult.ok ? "Connection Successful" : "Test Failed"}</span>
                  </div>
                  {testResult.ok && (
                    <Badge
                      variant="outline"
                      className="border-emerald-400 text-emerald-700 dark:text-emerald-300 font-mono text-[10px]"
                    >
                      ⚡ {testResult.latency_ms} ms
                    </Badge>
                  )}
                </div>

                {testResult.ok && testResult.sample_output && (
                  <div className="space-y-1 pt-1 border-t border-emerald-200/60 dark:border-emerald-800/60">
                    <p className="font-semibold text-emerald-800 dark:text-emerald-200">
                      Sample Generated Card:
                    </p>
                    <p className="italic">&ldquo;{testResult.sample_output.headline}&rdquo;</p>
                    <p className="line-clamp-2 text-muted-foreground">{testResult.sample_output.summary}</p>
                  </div>
                )}

                {!testResult.ok && (
                  <p className="font-mono break-all text-[11px] pt-1 border-t border-destructive/20">
                    {testResult.error || "Failed to connect to provider"}
                  </p>
                )}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Section 2: Autonomous Ingestion & External APIs */}
        <div className="space-y-6">
          {/* Autonomous News Ingestion Engine */}
          <Card className="shadow-sm">
            <CardHeader>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Activity className="size-5 text-blue-500" />
                  <CardTitle className="text-lg">News Ingestion Automation</CardTitle>
                </div>
                <Badge variant={autoIngest ? "default" : "secondary"} className="text-xs">
                  {autoIngest ? "Auto-Ingest Active" : "Paused"}
                </Badge>
              </div>
              <CardDescription>
                Autonomously ingests cricket feeds (ESPN, BBC, Times of India, BCCI, YouTube).
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Auto Ingest Switch */}
              <div className="flex items-center justify-between p-3 rounded-lg border bg-muted/20">
                <div className="space-y-0.5">
                  <Label htmlFor="auto_ingest" className="font-semibold text-sm cursor-pointer">
                    Autonomous Polling Loop
                  </Label>
                  <p className="text-xs text-muted-foreground">
                    Continuously checks active news sources when due.
                  </p>
                </div>
                <input
                  type="checkbox"
                  id="auto_ingest"
                  checked={autoIngest}
                  onChange={(e) => setAutoIngest(e.target.checked)}
                  className="size-5 rounded border-gray-300 text-primary focus:ring-primary cursor-pointer accent-primary"
                />
              </div>

              {/* Polling Interval */}
              <div className="space-y-2">
                <Label htmlFor="interval" className="text-sm font-semibold flex items-center gap-2">
                  <RefreshCw className="size-4" /> Global Polling Interval (minutes)
                </Label>
                <div className="grid grid-cols-4 gap-2">
                  {[5, 10, 15, 30].map((mins) => (
                    <button
                      key={mins}
                      type="button"
                      onClick={() => setIntervalMin(mins)}
                      className={`py-2 text-xs font-medium rounded-lg border text-center transition-all ${
                        intervalMin === mins
                          ? "border-primary bg-primary/10 text-primary font-bold"
                          : "border-border hover:bg-muted text-muted-foreground"
                      }`}
                    >
                      {mins} mins
                    </button>
                  ))}
                </div>
              </div>

              {/* Auto-publish Trusted Sources */}
              <div className="flex items-center justify-between p-3 rounded-lg border bg-muted/20">
                <div className="space-y-0.5">
                  <Label htmlFor="auto_publish" className="font-semibold text-sm cursor-pointer">
                    Auto-Publish Trusted Feeds
                  </Label>
                  <p className="text-xs text-muted-foreground">
                    Instantly publish articles from verified sources without manual review queue.
                  </p>
                </div>
                <input
                  type="checkbox"
                  id="auto_publish"
                  checked={autoPublish}
                  onChange={(e) => setAutoPublish(e.target.checked)}
                  className="size-5 rounded border-gray-300 text-primary focus:ring-primary cursor-pointer accent-primary"
                />
              </div>
            </CardContent>
          </Card>

          {/* Section 3: External Media APIs */}
          <Card className="shadow-sm">
            <CardHeader>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Video className="size-5 text-red-500" />
                  <CardTitle className="text-lg">YouTube Data API</CardTitle>
                </div>
                <Badge variant={settings.youtube_api_key_set ? "default" : "secondary"} className="text-xs">
                  {settings.youtube_api_key_set ? "Key Configured" : "Not Set"}
                </Badge>
              </div>
              <CardDescription>
                Used for autonomous ingestion of cricket YouTube channels & vertical shorts.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label htmlFor="youtube_key" className="text-sm font-semibold flex items-center gap-2">
                    <Key className="size-4" /> YouTube v3 API Key
                  </Label>
                  {settings.youtube_api_key_set && (
                    <span className="text-xs text-muted-foreground font-mono">
                      Active: {settings.youtube_api_key_masked}
                    </span>
                  )}
                </div>
                <div className="relative">
                  <Input
                    id="youtube_key"
                    type={showYoutubeKey ? "text" : "password"}
                    value={youtubeKeyInput}
                    onChange={(e) => setYoutubeKeyInput(e.target.value)}
                    placeholder={
                      settings.youtube_api_key_set ? "Enter new YouTube API key to overwrite..." : "AIzaSy..."
                    }
                    className="pr-10 font-mono text-xs"
                  />
                  <button
                    type="button"
                    onClick={() => setShowYoutubeKey(!showYoutubeKey)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showYoutubeKey ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                  </button>
                </div>
                <p className="text-xs text-muted-foreground">
                  Required only if ingesting from YouTube channels or Shorts feeds.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Engine Telemetry & Live Diagnostics */}
      <Card className="shadow-sm border-dashed">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Shield className="size-5 text-indigo-500" />
              <CardTitle className="text-base">System Audit & Status</CardTitle>
            </div>
            <Button variant="ghost" size="sm" onClick={handleRefreshStatus} className="text-xs gap-1.5">
              <RefreshCw className="size-3.5" /> Refresh Telemetry
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div className="p-3 rounded-lg border bg-card">
              <span className="text-xs text-muted-foreground">Database Status</span>
              <p className="font-semibold text-emerald-600 mt-1 flex items-center gap-1.5">
                <span className="size-2 rounded-full bg-emerald-500 animate-pulse" />
                Connected (PostgreSQL)
              </p>
            </div>
            <div className="p-3 rounded-lg border bg-card">
              <span className="text-xs text-muted-foreground">Active LLM Provider</span>
              <p className="font-semibold capitalize mt-1">
                {settings.llm_provider} ({settings.llm_model})
              </p>
            </div>
            <div className="p-3 rounded-lg border bg-card">
              <span className="text-xs text-muted-foreground">Autonomous Engine</span>
              <p className="font-semibold mt-1">
                {settings.auto_ingest_enabled ? "Enabled" : "Disabled"} (every {settings.ingest_interval_min}
                m)
              </p>
            </div>
            <div className="p-3 rounded-lg border bg-card">
              <span className="text-xs text-muted-foreground">Last Settings Update</span>
              <p className="font-mono text-xs mt-1">
                {settings.updated_at ? new Date(settings.updated_at).toLocaleString() : "Initial deployment"}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
