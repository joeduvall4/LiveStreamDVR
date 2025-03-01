<template>
    <form
        v-if="!loading && fetchedSettingsFields && formData"
        method="POST"
        enctype="multipart/form-data"
        action="#"
        @submit.prevent="submitForm"
    >
        <div class="field">
            <input
                v-model="searchText"
                class="input"
                type="text"
                :placeholder="t('input.search')"
            >
        </div>
        <div
            v-if="newAndInterestingSettings"
            class="new-and-interesting"
        >
            <h3>
                {{ t('views.settings.new_and_interesting') }}
            </h3>
            <ul>
                <li
                    v-for="(setting, key) of newAndInterestingSettings"
                    :key="key"
                >
                    Under <strong>{{ setting.group }}</strong>: {{ setting.text }} ({{ setting.help }})
                </li>
            </ul>
        </div>
        <details
            v-for="groupData in settingsGroups"
            :key="groupData.name"
            class="settings-details"
            :open="searchText !== ''"
        >
            <summary>{{ te('configgroup.' + groupData.name) ? t('configgroup.' + groupData.name) : groupData.name }}</summary>
            <div
                v-for="(data, key) of groupData.fields"
                :key="key"
                class="field"
            >
                <label
                    v-if="data.type != 'boolean'"
                    class="label"
                    :for="`input_${key}`"
                >
                    {{ te('config.' + key) ? t('config.' + key) : data.text }} <span
                        v-if="data.required"
                        class="required"
                    >*</span>
                    <span
                        v-if="data.deprecated"
                        class="is-small is-error"
                    >Deprecated</span>
                </label>

                <!-- boolean -->
                <div
                    v-if="data.type == 'boolean' && formData"
                    class="control"
                >
                    <label class="checkbox">
                        <input
                            :id="`input_${key}`"
                            v-model="(formData.config[key] as boolean)"
                            type="checkbox"
                            :name="key"
                        >
                        {{ data.text }}
                    </label>
                </div>

                <!-- string -->
                <div
                    v-if="data.type == 'string'"
                    class="control"
                >
                    <input
                        v-if="!data.multiline"
                        :id="`input_${key}`"
                        v-model="formData.config[key]"
                        class="input"
                        type="text"
                        :name="key.toString()"
                        :title="data.help"
                        :pattern="data.pattern"
                    >
                    <textarea
                        v-if="data.multiline"
                        :id="`input_${key}`"
                        v-model="(formData.config[key] as string)"
                        class="input textarea"
                        :name="key.toString()"
                        :title="data.help"
                        :pattern="data.pattern"
                    />
                </div>

                <!-- number -->
                <div
                    v-if="data.type == 'number'"
                    class="control"
                >
                    <input
                        :id="`input_${key}`"
                        v-model.number="formData.config[key]"
                        class="input"
                        type="number"
                        :name="key"
                    >
                </div>

                <!-- array -->
                <div
                    v-if="data.type == 'array'"
                    class="control"
                >
                    <!--<input class="input" :name="key" :id="key" :value="settings[key]" />-->
                    <div class="select">
                        <select
                            v-if="data.choices"
                            :id="`input_${key}`"
                            v-model="formData.config[key]"
                            class="input"
                            :name="key"
                            :data-is-array="data.choices && Array.isArray(data.choices)"
                        >
                            <template v-if="data.choices && Array.isArray(data.choices)">
                                <option
                                    v-for="(item, ix) in data.choices"
                                    :key="ix"
                                    :selected="
                                        (formData.config[key] !== undefined && formData.config[key] === item) ||
                                            (formData.config[key] === undefined && item === data.default)
                                    "
                                >
                                    {{ item }}
                                </option>
                            </template>
                            <template v-else>
                                <option
                                    v-for="(item, ix) in data.choices"
                                    :key="ix"
                                    :value="ix"
                                    :selected="
                                        (formData.config[key] !== undefined && formData.config[key] === item) ||
                                            (formData.config[key] === undefined && ix === data.default)
                                    "
                                >
                                    {{ item }}
                                </option>
                            </template>
                        </select>
                        <span v-else class="is-error">No choices defined</span>
                    </div>
                </div>

                <!-- template -->
                <div
                    v-if="data.type == 'template'"
                    class="control"
                >
                    <textarea
                        v-if="data.multiline"
                        :id="`input_${key}`"
                        v-model="(formData.config[key] as string)"
                        class="input"
                        type="text"
                        :name="key"
                    />
                    <input
                        v-else
                        :id="`input_${key}`"
                        v-model="formData.config[key]"
                        class="input"
                        type="text"
                        :name="key"
                    >
                    <ul class="template-replacements">
                        <li
                            v-for="(item, ix) in data.replacements"
                            :key="ix"
                        >
                            <button
                                v-if="item.deprecated"
                                type="button"
                                class="deprecated"
                                title="Deprecated"
                                @click="insertReplacement(key, ix)"
                            >
                                <span class="strikethrough">&lbrace;{{ ix }}&rbrace;</span>
                            </button>
                            <button
                                v-else
                                type="button"
                                @click="insertReplacement(key, ix)"
                            >
                                &lbrace;{{ ix }}&rbrace;
                            </button>
                        </li>
                    </ul>
                    <p class="template-preview">
                        {{ templatePreview(data, formData.config[key] as string) }}
                    </p>
                </div>

                <p
                    v-if="data.help"
                    class="input-help"
                >
                    {{ data.help }}
                </p>
                <p
                    v-if="data.default !== undefined"
                    class="input-default"
                >
                    Default: {{ data.default }}
                </p>
                <!--<p v-if="data.secret" class="input-secret">This is a secret field, keep blank to keep current value.</p>-->
            </div>
        </details>

        <br>

        <FormSubmit
            :form-status="formStatus"
            :form-status-text="formStatusText"
        >
            <div class="control">
                <d-button
                    color="success"
                    type="submit"
                    icon="save"
                >
                    {{ t('buttons.save') }}
                </d-button>
            </div>
        </FormSubmit>

        <div class="control">
            <hr>
            <d-button
                color="success"
                type="button"
                icon="globe"
                @click="doValidateExternalURL"
            >
                {{ t('forms.config.validate-external-url') }}
            </d-button>
        </div>
    </form>
    <LoadingBox v-if="loading" />
    <hr>
    <div class="auths">
        <youtube-auth />
        <twitch-auth />
    </div>
</template>

<script lang="ts" setup>
import { useStore } from "@/store";
import type { ApiResponse, ApiSettingsResponse } from "@common/Api/Api";
import type { SettingField } from "@common/Config";
import axios, { AxiosError } from "axios";
import { computed, onMounted, ref } from "vue";
import { formatString } from "@common/Format";
import YoutubeAuth from "@/components/YoutubeAuth.vue";
import TwitchAuth from "@/components/TwitchAuth.vue";
import FormSubmit from "@/components/reusables/FormSubmit.vue";
import type { settingsFields } from "@common/ServerConfig";

import { library } from "@fortawesome/fontawesome-svg-core";
import { faGlobe, faSave } from "@fortawesome/free-solid-svg-icons";
import { useI18n } from "vue-i18n";
import type { FormStatus } from "@/twitchautomator";
library.add(faGlobe, faSave);

interface SettingsGroup {
    name: string;
    fields: Record<string, SettingField<string | number | boolean>>;
}

// emit
const emit = defineEmits(["formSuccess"]);

// setup
const store = useStore();
const { t, te } = useI18n();

// data
const formStatusText = ref<string>("Ready");
const formStatus = ref<FormStatus>("IDLE");
const formData = ref<{ config: Record<string, string | number | boolean> }>({ config: {} });
const fetchedSettingsFields = ref<typeof settingsFields>({});
const loading = ref<boolean>(false);
const searchText = ref<string>("");

// computed
const settingsGroups = computed((): SettingsGroup[] => {
    if (!fetchedSettingsFields.value) return [];
    const groups: Record<string, SettingsGroup> = {};
    for (const key in fetchedSettingsFields.value) {
        const field = fetchedSettingsFields.value[key];
        if (!field.group) continue;
        if (searchText.value) {
            if (
                !key.toLowerCase().includes(searchText.value.toLowerCase()) &&
                !field.help?.toLowerCase().includes(searchText.value.toLowerCase()) &&
                !field.text?.toLowerCase().includes(searchText.value.toLowerCase())
            ) continue;
        }
        if (!groups[field.group]) groups[field.group] = { name: field.group, fields: {} };
        groups[field.group].fields[key] = field;
    }
    // return Object.values(groups).filter((group) => group.fields.length > 0);
    return Object.values(groups);

    /*
    return Object.values(groups).filter((group) => {
        if (!searchText.value) return true;
        return group.fields.some((field) => {
            return field.key.toLowerCase().includes(searchText.value.toLowerCase());
        });
    });
    */
});

const newAndInterestingSettings = computed((): typeof settingsFields => {
    const newSettings: typeof settingsFields = {};
    for (const key in fetchedSettingsFields.value) {
        const field = fetchedSettingsFields.value[key];
        if (field.new) newSettings[key] = field;
    }
    return newSettings;
    // return fetchedSettingsFields.value.filter((field) => field.new);
});

/*
settingsGroups(): Record<string, ApiSettingsField[]> {
    if (!settingsFields.value) return {};
    let data: Record<string, ApiSettingsField[]> = {};

    for (const key in settingsFields.value) {
        const field = settingsFields.value[key];
        if (!data[field.group]) data[field.group] = [];
        data[field.group].push(field);
    }
    console.log("settingsGroups", data);

    data = Object.keys(data)
        .sort()
        .reduce((obj: any, key) => {
            obj[key] = data[key];
            return obj;
        }, {});

    console.log("settingsGroups sort", data);
    return data;
},
*/

onMounted(() => {
    fetchData();
});
/*
created: {
    formData.value = this.settingsData;
},
*/
// methods
function fetchData(): void {
    loading.value = true;
    axios.get<ApiSettingsResponse>("/api/v0/settings").then((response) => {
        const data = response.data;
        formData.value.config = data.data.config;
        fetchedSettingsFields.value = data.data.fields;

        // set defaults
        for (const key in fetchedSettingsFields.value) {
            const field = fetchedSettingsFields.value[key];
            if (field.default !== undefined && formData.value.config[key] === undefined) {
                formData.value.config[key] = field.default;
            }
        }

    }).finally(() => {
        loading.value = false;
    });
}

function submitForm(event: Event) {

    formStatusText.value = t("messages.loading");
    formStatus.value = "LOADING";

    axios
        .put<ApiResponse>(`/api/v0/settings`, formData.value)
        .then((response) => {
            const json: ApiResponse = response.data;
            formStatusText.value = json.message || "No message";
            formStatus.value = json.status;
            if (json.message) alert(json.message);
            if (json.status == "OK") {
                emit("formSuccess", json);
                window.location.reload();
            }
            console.debug("settings save response", response);
        })
        .catch((err: AxiosError<ApiResponse>) => {
            console.error("form error", err.response);
            formStatusText.value = err.response?.data ? ( err.response.data.message || "Unknown error" ) : "Fatal error";
            // formStatusText.value = err.response.message ? err.response.message : "Fatal error";
            formStatus.value = "ERROR";
        });

    event.preventDefault();
    return false;
}

function configValue(key: string): string | number | boolean | undefined {
    if (!formData.value) return undefined;
    // const k: keyof ApiConfig = key as keyof ApiConfig;
    // return formData.value[k] as unknown as T;
    return formData.value.config[key];
}

function doValidateExternalURL() {
    axios
        .post<ApiResponse>(`/api/v0/settings/validate_url`)
        .then((response) => {
            const json: ApiResponse = response.data;
            if (json.message) alert(json.message);
        })
        .catch((err: AxiosError<ApiResponse>) => {
            console.error("form error", err.response);
            if (err.response?.data) {
                alert(err.response.data.message);
            } else {
                alert("Fatal error");
            }
        });
}

function templatePreview(data: SettingField<any>, template: string): string {
    // console.debug("templatePreview", data, template);
    if (!data.replacements) return "";
    const replaced_string = formatString(template, Object.fromEntries(Object.entries(data.replacements).map(([key, value]) => [key, value.display])));
    if (data.context) {
        // return data.context.replace(/{template}/g, replaced_string);
        return formatString(data.context, Object.fromEntries(Object.entries(data.replacements).map(([key, value]) => [key, value.display]))).replace(/{template}/g, replaced_string);
    } else {
        return replaced_string;
    }
}

function insertReplacement(key: string, value: string) {
    const input = document.getElementById(`input_${key}`) as HTMLInputElement;
    if (input) {
        const caret = input.selectionStart;
        if (caret !== null) {
            const rep = `{${value}}`;
            // input.value = input.value.substring(0, caret) + rep + input.value.substring(caret);
            const newValue = input.value.substring(0, caret) + rep + input.value.substring(caret);
            formData.value.config[key] = newValue;
            // console.debug("insertReplacement", newValue, formData.value[key]);
            input.selectionStart = caret + rep.length;
            input.selectionEnd = caret + rep.length;
            input.focus();
            // console.debug("insertReplacement", "caret", caret, key, value, input.value);
        } else {
            formData.value.config[key] = formData.value.config[key] + `{${value}}`;
            // console.debug("insertReplacement", "no caret", key, value, input.value);
        }
        // const text = input.value;
        // input.value = text.substring(0, caret) + value + text.substring(caret);
    } else {
        console.error("input not found", key);
    }
}
    

</script>

<style lang="scss" scoped>
.deprecated {
    background-color: #c13e3e;
    &:hover {
        background-color: #d44949;
    }
}

.auths {
    display: flex;
    flex-direction: column;
    gap: 1em;
}

.new-and-interesting {
    background-color: rgba(66, 164, 238, 0.1);
    padding: 1em;
    border-radius: 1em;
    margin-bottom: 1em;
    ul {
        margin: 0.5em 0;
        padding: 0 1.5em;
    }
}

</style>