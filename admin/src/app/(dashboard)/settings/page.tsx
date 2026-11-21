import type { Metadata } from "next";
import { NewsroomShell } from "@/components/newsroom/shell";
import { SettingsManager, type AppSettingsData } from "@/components/newsroom/settings-manager";
import { loadOrLogin } from "@/lib/api/server";

export const metadata: Metadata = { title: "Settings" };

export default async function SettingsPage() {
  const [me, settingsRes] = await Promise.all([
    loadOrLogin<{ id: string; permissions: string[] }>("/admin/v1/me"),
    loadOrLogin<AppSettingsData>("/admin/v1/settings"),
  ]);

  const fallbackSettings: AppSettingsData = {
    llm_provider: "anthropic",
    llm_api_key_set: false,
    llm_api_key_masked: "",
    llm_model: "claude-3-5-haiku-20241022",
    youtube_api_key_set: false,
    youtube_api_key_masked: "",
    auto_ingest_enabled: true,
    ingest_interval_min: 15,
    auto_publish_trusted: true,
    extra_config: {},
  };

  const currentSettings = settingsRes.data || fallbackSettings;

  return (
    <NewsroomShell
      title="Settings"
      description="Dynamic runtime settings for the app owner. Configure AI providers, secret API keys, and autonomous newsroom ingestion."
      error={settingsRes.error || me.error}
    >
      <SettingsManager initialSettings={currentSettings} />
    </NewsroomShell>
  );
}
