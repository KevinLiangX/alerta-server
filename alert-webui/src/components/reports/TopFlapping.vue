<template>
  <div>
    <v-card>
      <v-card-title primary-title>
        <div>
          <div class="headline">
            {{ $t('Top') }} {{ rowsPerPage }} {{ $t('Flapping') }}
          </div><br>
          <span class="grey--text">{{ $t('TopFlappingDescription') }}</span>
        </div>
        <v-spacer />
      </v-card-title>
      <v-data-table
        :headers="headers"
        :items="top10"
        class="px-2 pb-2"
        hide-actions
        :no-data-text="$t('NoDataAvailable')"
      >
        <template
          slot="items"
          slot-scope="props"
        >
          <td class="py-2">
            <div class="font-weight-medium mb-1">{{ props.item.event }}</div>
            <div class="caption grey--text text-truncate" style="max-width: 300px;">
              {{ props.item.resources.map(r => r.resource).join(', ') }}
            </div>
          </td>
          <td class="text-xs-left">
            <span class="font-weight-bold">{{ props.item.count }}</span>
          </td>
          <td class="text-xs-center grey--text">
            {{ props.item.duplicateCount }}
          </td>
          <td class="caption">{{ props.item.environments.join(', ') }}</td>
          <td class="caption">{{ props.item.services.join(', ') }}</td>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script>
import i18n from '@/plugins/i18n'

export default {
  data: () => ({
    headers: [
      {text: i18n.t('Event'), value: 'event', sortable: false},
      {text: i18n.t('Count'), value: 'count', sortable: false},
      {text: i18n.t('DuplCount'), value: 'duplicateCount', sortable: false},
      {text: i18n.t('Environment'), value: 'environment', sortable: false},
      {text: i18n.t('Services'), value: 'services', sortable: false},
      {text: i18n.t('Resources'), value: 'resources', sortable: false},
    ]
  }),
  computed: {
    top10() {
      if (this.filter) {
        return this.$store.state.reports.flapping
          .filter(alert =>
            this.filter.text
              ? Object.keys(alert).some(k => alert[k] && alert[k].toString().toLowerCase().includes(this.filter.text.toLowerCase()))
              : true
          )
      } else {
        return this.$store.state.reports.flapping
      }
    },
    filter() {
      return this.$store.state.reports.filter
    },
    rowsPerPage() {
      return this.$store.state.reports.pagination.rowsPerPage
    },
    refresh() {
      return this.$store.state.refresh
    },

  },
  watch: {
    filter: {
      handler(val) {
        this.getTopFlapping()
      },
      deep: true
    },
    rowsPerPage(val) {
      this.getTopFlapping()
    },
    refresh(val) {
      val || this.getTopFlapping()
    }
  },
  created() {
    this.getTopFlapping()
  },
  methods: {
    getTopFlapping() {
      return this.$store.dispatch('reports/getTopFlapping')
    }
  }
}
</script>

<style></style>
