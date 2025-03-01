<template>
    <div v-if="!initialLoad">
        <p class="error">
            {{ t('messages.changing-values-here-will-most-likely-require-a-restart') }}
        </p>
        <div class="field">
            <input
                v-model="searchText"
                class="input"
                type="text"
                :placeholder="t('input.search')"
            >
        </div>
        <table
            v-if="keyvalue && Object.keys(keyvalue).length > 0"
            class="table is-fullwidth is-striped is-hoverable"
        >
            <thead key="header">
                <tr>
                    <th>Key</th>
                    <th>Value</th>
                    <th>Created</th>
                    <th>Expires</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tr
                v-for="(kvdata, key) in sortedKeyValues"
                :key="key"
            >
                <td>{{ key }}</td>
                <td>
                    {{ kvdata.value }}
                    <button
                        class="icon-button"
                        title="Edit"
                        @click="editKeyValue(key, kvdata.value)"
                    >
                        <span><font-awesome-icon icon="pencil" /></span>
                    </button>
                </td>
                <td>{{ formatDate(kvdata.created) }}</td>
                <td>{{ kvdata.expires ? formatDate(kvdata.expires) : "" }}</td>
                <td>
                    <d-button
                        icon="trash"
                        color="danger"
                        size="small"
                        @click="deleteKeyValue(key)"
                    >
                        {{ t('buttons.delete') }}
                    </d-button>
                </td>
            </tr>
            <tr key="deleteall">
                <td colspan="999">
                    <d-button
                        icon="trash"
                        color="danger"
                        @click="deleteAllKeyValues"
                    >
                        {{ t('buttons.delete-all') }}
                    </d-button>
                </td>
            </tr>
        </table>
        <p v-else>
            No key-value data found.
        </p>

        <hr>

        <form @submit.prevent="doAdd">
            <div class="field">
                <label
                    for="key"
                    class="label"
                >{{ t('forms.keyvalue.key') }}</label>
                <div class="control">
                    <input
                        id="key"
                        v-model="addForm.key"
                        class="input"
                        type="text"
                    >
                </div>
            </div>
            <div class="field">
                <label
                    for="value"
                    class="label"
                >{{ t('forms.keyvalue.value') }}</label>
                <div class="control">
                    <input
                        id="value"
                        v-model="addForm.value"
                        class="input"
                        type="text"
                    >
                </div>
                <p class="input-help">
                    The value will be stored as a string, and depending on how it is used, it might be converted to another type.
                </p>
            </div>
            <div class="field">
                <div class="control">
                    <d-button
                        icon="plus"
                        color="success"
                        type="submit"
                    >
                        {{ t('buttons.create') }}
                    </d-button>
                </div>
            </div>
        </form>
    </div>
    <LoadingBox v-if="initialLoad" />
</template>

<script lang="ts" setup>
import { useStore } from "@/store";
import { computed, onMounted, ref } from "vue";
import type { ApiResponse } from "@common/Api/Api";
import { library } from "@fortawesome/fontawesome-svg-core";
import { faPencil, faSync, faTrash, faPlus } from "@fortawesome/free-solid-svg-icons";
import { useI18n } from "vue-i18n";
import axios from "axios";
import { formatDate } from "@/mixins/newhelpers";
library.add(faPencil, faSync, faTrash, faPlus);

// emit
const emit = defineEmits(["formSuccess"]);

// setup
const store = useStore();
const { t } = useI18n();

interface KeyValueData {
    value: string;
    created: Date;
    expires?: Date;
}

// data
const keyvalue = ref<Record<string, KeyValueData>>();
const initialLoad = ref(true);
const searchText = ref("");
const addForm = ref<{ key: string; value: string }>({ key: "", value: "" });

// computed
const sortedKeyValues = computed((): Record<string, KeyValueData> => {
    if (!keyvalue.value) return {};
    let entries = Object.entries(keyvalue.value);
    if (searchText.value !== "") entries = entries.filter(e => e[0].includes(searchText.value));
    return Object.fromEntries(entries.sort());
});

onMounted(() => {
    fetchData();
});

function fetchData(): void {
    axios
        .get<ApiResponse>(`/api/v0/keyvalue`)
        .then((response) => {
            const json = response.data;
            const kv = json.data;
            // console.debug("kv", kv);
            keyvalue.value = kv;
        })
        .catch((err) => {
            console.error("fetch data error", err.response);
        })
        .finally(() => {
            initialLoad.value = false;
        });
}

function deleteKeyValue(key: string) {
    axios
        .delete(`/api/v0/keyvalue/${key}`)
        .then((response) => {
            const json = response.data;
            console.debug("deleteKeyValue", json);
            // alert(`Deleted key ${key}`);
            fetchData();
        })
        .catch((err) => {
            console.error("delete error", err.response);
        });
}

function deleteAllKeyValues() {
    axios
        .delete(`/api/v0/keyvalue`)
        .then((response) => {
            const json = response.data;
            console.debug("deleteAllKeyValues", json);
            alert(`Deleted all key values`);
            fetchData();
        })
        .catch((err) => {
            console.error("delete all error", err.response);
        });
}

function editKeyValue(key: string, value: string) {
    const new_value = prompt(`Edit value for key ${key}`, value);
    if (!new_value || new_value == value) return;
    axios
        .put(`/api/v0/keyvalue/${key}`, { value: new_value })
        .then((response) => {
            const json = response.data;
            console.debug("editKeyValue", json);
            fetchData();
        })
        .catch((err) => {
            console.error("edit error", err.response);
            if (err.response && err.response.data && err.response.data.message) {
                alert(err.response.data.message);
            }
        });
}

function doAdd() {
    axios
        .put(`/api/v0/keyvalue/${addForm.value.key}`, { value: addForm.value.value })
        .then((response) => {
            const json = response.data;
            console.debug("doAdd", json);
            fetchData();
            addForm.value.key = "";
            addForm.value.value = "";
            // this.$emit("formSuccess");
        }).catch((err) => {
            console.error("add error", err.response);
            if (err.response && err.response.data && err.response.data.message) {
                alert(err.response.data.message);
            }
        });
}
    
</script>
