angular.module('loomioApp').controller 'DashboardPageController', ($rootScope, $scope, Records, CurrentUser, LoadingService, ThreadQueryService) ->
  $rootScope.$broadcast('currentComponent', { page: 'dashboardPage' })
  $rootScope.$broadcast('setTitle', 'Dashboard')
  $rootScope.$broadcast('analyticsClearGroup')

  Records.votes.fetchMyRecentVotes()

  @perPage = 50
  @loaded =
    show_all:           0
    show_muted:         0
    show_participating: 0

  @views =
    recent: {}
    groups: {}

  @timeframes =
    today:     { from: '1 second ago', to: '-10 year ago' } # into the future!
    yesterday: { from: '1 day ago',    to: '1 second ago' }
    thisweek:  { from: '1 week ago',   to: '1 day ago' }
    thismonth: { from: '1 month ago',  to: '1 week ago' }
    older:     { from: '3 month ago',  to: '1 month ago' }
  @timeframeNames = _.map @timeframes, (timeframe, name) -> name

  @recentViewNames = ['proposals', 'starred', 'today', 'yesterday', 'thisweek', 'thismonth', 'older']

  @groupThreadLimit = 5
  @groups = -> CurrentUser.parentGroups()
  @moreForThisGroup = (group) -> @views.groups[group.key].length() > @groupThreadLimit

  @displayByGroup = ->
    _.contains ['show_muted'], @filter

  @updateQueries = =>
    @currentBaseQuery = ThreadQueryService.filterQuery(@filter)
    if @displayByGroup()
      _.each @groups(), (group) =>
        @views.groups[group.key] = ThreadQueryService.groupQuery(group, { filter: @filter, queryType: 'all' })
    else
      @views.recent.proposals = ThreadQueryService.filterQuery ['show_proposals', @filter], queryType: 'important'
      @views.recent.starred   = ThreadQueryService.filterQuery ['show_starred', 'hide_proposals', @filter], queryType: 'important'
      _.each @timeframeNames, (name) =>
        @views.recent[name] = ThreadQueryService.timeframeQuery
          name: name
          filter: @filter
          timeframe: @timeframes[name]

  @loadMore = =>
    from = @loaded[@filter]
    @loaded[@filter] = @loaded[@filter] + @perPage

    Records.discussions.fetchDashboard(
      filter: @filter
      from:   from
      per:    @perPage).then @updateQueries
  LoadingService.applyLoadingFunction @, 'loadMore'

  @refresh = =>
    @updateQueries()
    @loadMore() if @loaded[@filter] == 0

  @setFilter = (filter = 'show_all') =>
    @filter = filter
    @refresh()
  @setFilter()
  $scope.$on 'homePageClicked', => @setFilter()
  $scope.$on 'starToggled', @refresh

  return
