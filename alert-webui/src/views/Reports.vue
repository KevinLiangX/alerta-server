<template>
  <div class="reports pa-4 grey lighten-5">
    <!-- KPI Summary Cards -->
    <v-layout row wrap class="mb-4">
      <v-flex xs12 sm4 class="pa-2">
        <v-card class="elevation-1 border-left-primary">
          <v-card-text class="pa-3">
            <div class="overline grey--text mb-1">{{ $t('Top') }} {{ $t('Offender') }}</div>
            <div class="headline font-weight-bold primary--text">
              {{ topOffender ? topOffender.event : '--' }}
            </div>
            <div class="caption grey--text mt-1">
              {{ topOffender ? topOffender.count : 0 }} {{ $t('Alerts') }}
            </div>
          </v-card-text>
        </v-card>
      </v-flex>
      <v-flex xs12 sm4 class="pa-2">
        <v-card class="elevation-1 border-left-orange">
          <v-card-text class="pa-3">
            <div class="overline grey--text mb-1">{{ $t('Top') }} {{ $t('Flapping') }}</div>
            <div class="headline font-weight-bold orange--text">
              {{ topFlapping ? topFlapping.event : '--' }}
            </div>
            <div class="caption grey--text mt-1">
              {{ topFlapping ? topFlapping.count : 0 }} {{ $t('Changes') }}
            </div>
          </v-card-text>
        </v-card>
      </v-flex>
      <v-flex xs12 sm4 class="pa-2">
        <v-card class="elevation-1 border-left-error">
          <v-card-text class="pa-3">
            <div class="overline grey--text mb-1">{{ $t('Top') }} {{ $t('Standing') }}</div>
            <div class="headline font-weight-bold error--text text-truncate">
              {{ topStanding ? topStanding.event : '--' }}
            </div>
            <div class="caption grey--text mt-1">
              {{ topStanding ? topStanding.count : 0 }} {{ $t('Alerts') }}
            </div>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>

    <!-- Filter Actions Bar -->
    <v-layout row align-center class="mb-4 px-2">
      <div class="title font-weight-medium grey--text text--darken-2">
        {{ $t('Reports') }}
      </div>
      <v-spacer />
      <v-flex xs1 class="mr-3">
        <v-select
          v-model.number="rowsPerPage"
          :items="rowsPerPageItems"
          label="Top"
          hide-details
          solo
          flat
          background-color="white"
          class="reports-top-select"
        />
      </v-flex>

      <v-btn
        flat
        icon
        :class="{ 'filter-active': isActive }"
        @click="sidesheet = !sidesheet"
      >
        <v-badge color="red" overlap :value="activeFilters.length > 0">
          <template v-slot:badge>
            <span>{{ activeFilters.length }}</span>
          </template>
          <v-icon>filter_list</v-icon>
        </v-badge>
      </v-btn>
    </v-layout>

    <!-- Filter Chips Bar -->
    <v-fade-transition>
      <div v-if="activeFilters.length > 0" class="filter-bar white elevation-1 rounded mb-4 pa-2 d-flex align-center wrap">
        <v-chip
          v-for="f in activeFilters"
          :key="f.id"
          small
          close
          outline
          label
          color="primary"
          class="ma-1"
          @input="removeFilter(f)"
        >
          <span class="font-weight-medium mr-1">{{ f.label }}:</span>
          <span>{{ f.text }}</span>
        </v-chip>
        <v-btn
          flat
          small
          color="grey darken-1"
          class="text-none ml-2"
          @click="clearAllFilters"
        >
          <v-icon left small v-if="isRefreshing" class="spinning">refresh</v-icon>
          {{ $t('ClearAll') }}
        </v-btn>
      </div>
    </v-fade-transition>

    <!-- Main Reports Grid -->
    <v-layout row wrap>
      <v-flex xs12 lg6 class="pa-2">
        <top-offenders />
      </v-flex>
      <v-flex xs12 lg6 class="pa-2">
        <top-flapping />
      </v-flex>
      <v-flex xs12 class="pa-2 mt-2">
        <top-standing />
      </v-flex>
    </v-layout>

    <report-filter
      :value="sidesheet"
      @close="sidesheet = false"
    />
  </div>
</template>

<script>
import TopOffenders from '@/components/reports/TopOffenders.vue'
import TopFlapping from '@/components/reports/TopFlapping.vue'
import TopStanding from '@/components/reports/TopStanding.vue'

import i18n from '@/plugins/i18n'

export default {
  components: {
    TopOffenders,
    TopFlapping,
    TopStanding,
    ReportFilter: () => import('@/components/reports/ReportFilter.vue')
  },
  data: () => ({
    sidesheet: false,
    isRefreshing: false,
    rowsPerPageItems: [10, 20, 50, 100, 200]
  }),
  computed: {
    topOffender() {
      return this.$store.state.reports.offenders[0]
    },
    topFlapping() {
      return this.$store.state.reports.flapping[0]
    },
    topStanding() {
      return this.$store.state.reports.standing[0]
    },
    filter() {
      return this.$store.state.reports.filter
    },
    isActive() {
      return this.filter.text || this.filter.environment || this.filter.severity
        || this.filter.status || this.filter.customer || this.filter.service
        || this.filter.group || this.filter.dateRange[0] || this.filter.dateRange[1]
    },
    rowsPerPage: {
      get() {
        return this.$store.state.reports.pagination.rowsPerPage
      },
      set(value) {
        this.$store.dispatch('reports/setPageSize', value)
      }
    },
    activeFilters() {
      const chips = []
      if (this.filter.text) {
        chips.push({ id: 'text', label: this.$t('Search'), text: this.filter.text, type: 'text' })
      }
      if (this.filter.environment) {
        chips.push({ id: 'env', label: this.$t('Environment'), text: this.filter.environment, type: 'environment' })
      }
      if (this.filter.status && this.filter.status.length > 0) {
        this.filter.status.forEach(s => {
          chips.push({ id: `status-${s}`, label: this.$t('Status'), text: this.$t('status_' + s), value: s, type: 'status' })
        })
      }
      if (this.filter.severity && this.filter.severity.length > 0) {
        this.filter.severity.forEach(s => {
          chips.push({ id: `severity-${s}`, label: this.$t('Severity'), text: s, value: s, type: 'severity' })
        })
      }
      return chips
    }
  },
  methods: {
    removeFilter(f) {
      if (f.type === 'text') {
        this.$store.dispatch('reports/setFilter', { text: null })
      } else if (f.type === 'environment') {
        this.$store.dispatch('reports/setFilter', { environment: null })
      } else if (f.type === 'status') {
        const newStatus = this.filter.status.filter(s => s !== f.value)
        this.$store.dispatch('reports/setFilter', { status: newStatus.length > 0 ? newStatus : null })
      } else if (f.type === 'severity') {
        const newSeverity = this.filter.severity.filter(s => s !== f.value)
        this.$store.dispatch('reports/setFilter', { severity: newSeverity.length > 0 ? newSeverity : null })
      }
    },
    clearAllFilters() {
      this.isRefreshing = true
      this.$store.dispatch('reports/setFilter', {
        text: null,
        environment: null,
        status: null,
        severity: null,
        customer: null,
        service: null,
        group: null,
        dateRange: [null, null]
      })
      // Trigger refreshes for all components
      Promise.all([
        this.$store.dispatch('reports/getTopOffenders'),
        this.$store.dispatch('reports/getTopFlapping'),
        this.$store.dispatch('reports/getTopStanding')
      ]).finally(() => {
        this.isRefreshing = false
      })
    }
  }
}
</script>
