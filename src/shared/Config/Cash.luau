-- All free factors, including display toilet factors, are capped before paid factors.
local freeCap, paidCap = 40, 3
return {
	FreeCap = freeCap,
	PaidCap = paidCap,
	TotalCap = freeCap * paidCap,
	Explanation = "Cash: free bonuses + toilet factor cap at 40x; paid factors cap at 3x on top (120x max).",
}
