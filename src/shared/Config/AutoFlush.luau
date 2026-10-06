return {
	IdleSeconds = 30 * 60,
	IdleWarningSeconds = 5 * 60,
	ActivityInterval = 15,
	ToastInterval = 3,
	ToastGain = 0.25,
	StatusGrace = 1, -- Allow scheduler/replication jitter, then show waiting instead of a false running state.
}
