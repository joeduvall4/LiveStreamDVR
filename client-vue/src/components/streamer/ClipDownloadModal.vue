<template>
    <div class="video-download-menu">
        <d-button
            v-if="isTwitch(streamer)"
            color="success"
            icon="download"
            @click="fetchTwitchClips"
        >
            {{ t('vod.fetch-clip-list') }}
        </d-button>
        <hr>
        <template v-if="!loading">
            <div
                v-for="clip in onlineClips"
                :key="clip.id"
                class="video-download-menu-item"
            >
                <h2>
                    <a
                        :href="clip.url"
                        rel="nofollow"
                        target="_blank"
                    >{{ clip.created_at }}</a>
                </h2>
                <img :src="imageUrl(clip.thumbnail_url, 320, 240)"><br>
                <p>{{ clip.title }}</p>
                <ul>
                    <li>{{ humanDuration(clip.duration) }}</li>
                    <li>{{ formatNumber(clip.view_count, 0) }} views</li>
                    <!--<li>Estimated size: {{ formatBytes(((averageVodBitrate || 6000000) / 10) * parseTwitchDuration(vod.duration)) }}</li>-->
                </ul>
                <br>
                <d-button
                    color="success"
                    icon="download"
                    size="small"
                    @click="downloadClip(clip)"
                >
                    {{ t("buttons.download") }}
                </d-button>
            </div>
        </template>
        <LoadingBox v-else />
    </div>
</template>

<script lang="ts" setup>
import { humanDuration, isTwitch, formatNumber } from '@/mixins/newhelpers';
import type { Clip } from '@common/TwitchAPI/Clips';
import axios from 'axios';
import { ref } from 'vue';
import { library } from "@fortawesome/fontawesome-svg-core";
import { faSpinner } from "@fortawesome/free-solid-svg-icons";
import { useI18n } from 'vue-i18n';
import type { ApiResponse } from "@common/Api/Api";
import type { ChannelTypes } from '@/twitchautomator';
library.add(faSpinner);

const props = defineProps<{
    streamer: ChannelTypes;
}>();

const { t } = useI18n();

const onlineClips = ref<Clip[]>([]);
const loading = ref(false);

// clips
async function fetchTwitchClips() {
    if (!props.streamer) return;
    loading.value = true;
    let response;

    try {
        response = await axios.get<ApiResponse>(`/api/v0/channels/${props.streamer.uuid}/clips`);
    } catch (error) {
        if (axios.isAxiosError(error)) {
            console.error("fetchTwitchClips error", error.response);
            if (error.response && error.response.data && error.response.data.message) {
                alert(error.response.data.message);
            }
        }
        loading.value = false;
        return;
    }

    const data = response.data;

    if (data.message) {
        alert(data.message);
    }

    console.log("Fetched", data);
    onlineClips.value = data.data;
    loading.value = false;
}

async function downloadClip(clip: Clip) {
    if (!props.streamer) return;

    let response;

    try {
        response = await axios.post<ApiResponse>(`/api/v0/tools/clip_download`, {
            url: clip.url,
        });
    } catch (error) {
        if (axios.isAxiosError(error)) {
            console.error("downloadClip error", error.response);
            if (error.response && error.response.data && error.response.data.message) {
                alert(error.response.data.message);
            }
        }
        return;
    }

    const data = response.data;

    if (data.message) {
        alert(data.message);
    }

    console.log("Downloaded", data);

}

function imageUrl(url: string, width: number, height: number) {
    if (!url) return "";
    return url.replace(/%\{width\}/g, width.toString()).replace(/%\{height\}/g, height.toString());
}

</script>

<style lang="scss" scoped>
.video-download-menu-item {
    background-color: rgba(0, 0, 0, 0.1);
    padding: 1em;
    &:not(:last-child) {
        margin-bottom: 1em;
    }
}

</style>