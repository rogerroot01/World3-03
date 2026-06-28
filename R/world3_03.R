# Native R port of the PyWorld3-03 fast World3 runner.
# Source model: ../PyWorld3-03-main/pyworld3, the 2004/STELLA-aligned fork.

world3_clip <- function(func2, func1, t, t_switch) {
  if (is.na(func1) || is.na(func2)) return(NA_real_)
  if (t <= t_switch) func1 else func2
}

world3_table <- function(tables, y_name) {
  hit <- NULL
  for (tbl in tables) {
    if (identical(tbl[["y.name"]], y_name)) {
      hit <- tbl
      break
    }
  }
  if (is.null(hit)) stop("Missing World3 table: ", y_name, call. = FALSE)
  x <- unlist(hit[["x.values"]], use.names = FALSE)
  y <- unlist(hit[["y.values"]], use.names = FALSE)
  force(x); force(y)
  function(v) approx(x, y, xout = v, rule = 2, ties = "ordered")$y
}

world3_make_smooth <- function(input, n, dt) {
  env <- new.env(parent = emptyenv())
  env$out <- rep(0, n)
  env$input <- input
  env$dt <- dt
  env
}

world3_smooth <- function(delay, k, delay_time, init_val) {
  if (k == 1) {
    delay$out[k] <- init_val
  } else {
    delay$out[k] <- delay$out[k - 1] +
      (delay$input[k - 1] - delay$out[k - 1]) * delay$dt / delay_time
  }
  delay$out[k]
}

world3_make_dlinf3 <- function(input, n, dt) {
  env <- new.env(parent = emptyenv())
  env$out <- matrix(0, nrow = n, ncol = 3)
  env$input <- input
  env$dt <- dt
  env
}

world3_dlinf3 <- function(delay, k, delay_time) {
  if (k == 1) {
    delay$out[k, ] <- delay$input[k]
  } else {
    prev <- delay$out[k - 1, ]
    dx1 <- delay$input[k - 1] - prev[1]
    dx2 <- prev[1] - prev[2]
    dx3 <- prev[2] - prev[3]
    delay$out[k, ] <- prev + c(dx1, dx2, dx3) * delay$dt * 3 / delay_time
  }
  delay$out[k, 3]
}

world3_load_tables <- function(json_file = NULL) {
  if (is.null(json_file)) {
    candidates <- c(
      file.path("data", "functions_table_world3.json"),
      file.path(".", "data", "functions_table_world3.json"),
      file.path("..", "data", "functions_table_world3.json"),
      file.path("..", "PyWorld3-03-main", "pyworld3", "functions_table_world3.json"),
      file.path("../..", "PyWorld3-03-main", "pyworld3", "functions_table_world3.json")
    )
    exists <- file.exists(candidates)
    if (!any(exists)) {
      stop("Could not find PyWorld3-03 table file from working directory: ",
           getwd(), call. = FALSE)
    }
    json_file <- candidates[which(exists)[1]]
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Install jsonlite to read World3 table functions.", call. = FALSE)
  }
  jsonlite::fromJSON(json_file, simplifyVector = FALSE)
}

world3_empty <- function(year_min = 1900, year_max = 2100, dt = 0.5,
                         pyear = 1975, pyear_res_tech = 4000,
                         pyear_pp_tech = 4000, pyear_fcaor = 4000,
                         pyear_y_tech = 4000, iphst = 1940,
                         tables_file = NULL) {
  n <- as.integer((year_max - year_min) / dt) + 1
  w <- list(
    year_min = year_min, year_max = year_max, dt = dt, n = n,
    time = seq(year_min, year_max, by = dt),
    pyear = pyear, pyear_res_tech = pyear_res_tech,
    pyear_pp_tech = pyear_pp_tech, pyear_fcaor = pyear_fcaor,
    pyear_y_tech = pyear_y_tech, iphst = iphst
  )

  constants <- list(
    p1i = 65e7, p2i = 70e7, p3i = 19e7, p4i = 6e7,
    dcfsn = 3.8, fcest = 4000, hsid = 20, ieat = 3, len = 28,
    lpd = 20, mtfn = 12, pet = 4000, rlt = 30, sad = 20, zpgt = 4000,
    ici = 2.1e11, sci = 1.44e11, iet = 4000, iopcd = 400,
    lfpf = 0.75, lufdt = 2, icor1 = 3, icor2 = 3, scor1 = 1,
    scor2 = 1, alic1 = 14, alic2 = 14, alsc1 = 20, alsc2 = 20,
    fioac1 = 0.43, fioac2 = 0.43,
    ali = 0.9e9, pali = 2.3e9, lfh = 0.7, palt = 3.2e9, pl = 0.1,
    alai1 = 2, alai2 = 2, io70 = 7.9e11, lyf1 = 1, sd = 0.07,
    uili = 8.2e6, alln = 1000, uildt = 10, lferti = 600, ilf = 600,
    fspd = 2, sfpc = 230, dfr = 2,
    pp19 = 2.5e7, apct = 4000, imef = 0.1, imti = 10, frpm = 0.02,
    ghup = 4e-9, faipm = 0.001, amti = 1, pptd = 20,
    ahl70 = 1.5, pp70 = 1.36e8, dppolx = 1.2, tdt = 20, ppgf1 = 1,
    nri = 1e12, nruf1 = 1, drur = 4.8e9
  )
  w <- c(w, constants)

  vars <- c(
    "pop", "p1", "p2", "p3", "p4", "d1", "d2", "d3", "d4",
    "mat1", "mat2", "mat3", "d", "cdr", "fpu", "le", "lmc", "lmf",
    "lmhs", "lmhs1", "lmhs2", "lmp", "m1", "m2", "m3", "m4",
    "ehspc", "hsapc", "b", "cbr", "cmi", "cmple", "tf", "dtf",
    "dcfs", "fce", "fie", "fm", "frsn", "mtf", "nfc", "ple",
    "sfsn", "aiopc", "diopc", "fcapc", "fcfpc", "fsafc", "lei",
    "gdpc", "gdpi", "ei", "hwi",
    "ic", "io", "icdr", "icir", "icor", "iopc", "alic", "fioac",
    "fioacc", "fioai", "fioacv", "cio", "ciopc", "sc", "so",
    "scdr", "scir", "scor", "sopc", "alsc", "isopc", "isopc1",
    "isopc2", "fioas", "fioas1", "fioas2", "cuf", "j", "jph",
    "jpicu", "jpscu", "lf", "luf", "lufd", "pjas", "pjis", "pjss",
    "al", "pal", "dcph", "f", "fpc", "fioaa", "fioaa1", "fioaa2",
    "ifpc", "ifpc1", "ifpc2", "ldr", "lfc", "tai", "ai", "aic",
    "aiph", "alai", "cai", "ly", "lyf", "lymap", "lymap1",
    "lymap2", "lymc", "fiald", "mlymc", "mpai", "mpld", "uil",
    "all", "llmy", "llmy1", "llmy2", "ler", "lrui", "uilpc",
    "uilr", "lfert", "lfd", "lfdr", "lfr", "lfrt", "falm", "fr",
    "pfr", "cpfr", "frd", "ytcm", "ytcr", "yt", "lyf2",
    "apfay", "ymap1", "ymap2", "fio70", "pii", "pcrum", "ppgi",
    "ppga", "ppgr", "ppar", "ppasr", "pp", "ahl", "ahlm", "ppolx",
    "pptc", "pptcm", "pptcr", "ppt", "ppgf2", "ppgf", "pptmi",
    "abl", "ef", "nr", "nrfr", "nruf", "nruf2", "nrur", "fcaor",
    "fcaor1", "fcaor2", "rtc", "rtcm", "rtcr", "rt"
  )
  vars <- unique(vars)
  for (v in vars) w[[v]] <- rep(NA_real_, n)

  tables <- world3_load_tables(tables_file)
  table_names <- c(
    "M1", "M2", "M3", "M4", "LMF", "HSAPC", "LMHS1", "LMHS2",
    "FPU", "CMI", "LMP", "FM", "CMPLE", "SFSN", "FRSN",
    "FCE_TOCLIP", "FSAFC", "LEI", "GDPC", "EI", "FIOACV",
    "ISOPC1", "ISOPC2", "FIOAS1", "FIOAS2", "JPICU", "JPSCU",
    "JPH", "CUF", "IFPC1", "IFPC2", "FIOAA1", "FIOAA2", "DCPH",
    "LYMC", "LYMAP1", "LYMAP2", "FIALD", "MLYMC", "LLMY1",
    "LLMY2", "UILPC", "LFDR", "LFRT", "FALM", "YTCM",
    "PCRUM", "FCAOR1", "FCAOR2", "RTCM", "AHLM", "PPTCM",
    "PPTMI", "YMAP1", "YMAP2"
  )
  w$fn <- list()
  for (nm in unique(table_names)) w$fn[[tolower(nm)]] <- world3_table(tables, nm)

  w$delay <- list(
    dlinf3_le = world3_make_dlinf3(w$le, n, dt),
    dlinf3_iopc = world3_make_dlinf3(w$iopc, n, dt),
    dlinf3_fcapc = world3_make_dlinf3(w$fcapc, n, dt),
    smooth_hsapc = world3_make_smooth(w$hsapc, n, dt),
    smooth_iopc = world3_make_smooth(w$iopc, n, dt),
    smooth_luf = world3_make_smooth(w$luf, n, dt),
    smooth_cai = world3_make_smooth(w$cai, n, dt),
    smooth_fr = world3_make_smooth(w$fr, n, dt),
    dlinf3_yt = world3_make_dlinf3(w$yt, n, dt),
    dlinf3_ppgr = world3_make_dlinf3(w$ppgr, n, dt),
    dlinf3_ppt = world3_make_dlinf3(w$ppt, n, dt),
    dlinf3_rt = world3_make_dlinf3(w$rt, n, dt)
  )
  w
}

world3_sync_delays <- function(w) {
  w$delay$dlinf3_le$input <- w$le
  w$delay$dlinf3_iopc$input <- w$iopc
  w$delay$dlinf3_fcapc$input <- w$fcapc
  w$delay$smooth_hsapc$input <- w$hsapc
  w$delay$smooth_iopc$input <- w$iopc
  w$delay$smooth_luf$input <- w$luf
  w$delay$smooth_cai$input <- w$cai
  w$delay$smooth_fr$input <- w$fr
  w$delay$dlinf3_yt$input <- w$yt
  w$delay$dlinf3_ppgr$input <- w$ppgr
  w$delay$dlinf3_ppt$input <- w$ppt
  w$delay$dlinf3_rt$input <- w$rt
  w
}

world3_update_population <- function(w, k, j = k - 1, jk = j, kl = k, state = TRUE) {
  if (state) {
    w$p1[k] <- w$p1[j] + w$dt * (w$b[jk] - w$d1[jk] - w$mat1[jk])
    w$p2[k] <- w$p2[j] + w$dt * (w$mat1[jk] - w$d2[jk] - w$mat2[jk])
    w$p3[k] <- w$p3[j] + w$dt * (w$mat2[jk] - w$d3[jk] - w$mat3[jk])
    w$p4[k] <- w$p4[j] + w$dt * (w$mat3[jk] - w$d4[jk])
  }
  w$pop[k] <- w$p1[k] + w$p2[k] + w$p3[k] + w$p4[k]
  w$fpu[k] <- w$fn$fpu(w$pop[k])
  w$lmp[k] <- w$fn$lmp(w$ppolx[k])
  w$lmf[k] <- w$fn$lmf(w$fpc[k] / w$sfpc)
  w$cmi[k] <- w$fn$cmi(w$iopc[k])
  w$hsapc[k] <- w$fn$hsapc(w$sopc[k])
  w <- world3_sync_delays(w)
  w$ehspc[k] <- world3_smooth(w$delay$smooth_hsapc, k, w$hsid, w$hsapc[1])
  w$lmhs1[k] <- w$fn$lmhs1(w$ehspc[k])
  w$lmhs2[k] <- w$fn$lmhs2(w$ehspc[k])
  w$lmhs[k] <- world3_clip(w$lmhs2[k], w$lmhs1[k], w$time[k], w$iphst)
  w$lmc[k] <- 1 - w$cmi[k] * w$fpu[k]
  w$le[k] <- w$len * w$lmf[k] * w$lmhs[k] * w$lmp[k] * w$lmc[k]
  w$m1[k] <- w$fn$m1(w$le[k]); w$m2[k] <- w$fn$m2(w$le[k])
  w$m3[k] <- w$fn$m3(w$le[k]); w$m4[k] <- w$fn$m4(w$le[k])
  w$mat1[kl] <- w$p1[k] * (1 - w$m1[k]) / 15
  w$mat2[kl] <- w$p2[k] * (1 - w$m2[k]) / 30
  w$mat3[kl] <- w$p3[k] * (1 - w$m3[k]) / 20
  w$d1[kl] <- w$p1[k] * w$m1[k]; w$d2[kl] <- w$p2[k] * w$m2[k]
  w$d3[kl] <- w$p3[k] * w$m3[k]; w$d4[kl] <- w$p4[k] * w$m4[k]
  w$d[k] <- w$d1[jk] + w$d2[jk] + w$d3[jk] + w$d4[jk]
  w$cdr[k] <- 1000 * w$d[k] / w$pop[k]
  w <- world3_sync_delays(w)
  w$aiopc[k] <- world3_smooth(w$delay$smooth_iopc, k, w$ieat, w$iopc[1])
  w$diopc[k] <- world3_dlinf3(w$delay$dlinf3_iopc, k, w$sad)
  w$fie[k] <- (w$iopc[k] - w$aiopc[k]) / w$aiopc[k]
  w$sfsn[k] <- w$fn$sfsn(w$diopc[k])
  w$frsn[k] <- w$fn$frsn(w$fie[k])
  w$dcfs[k] <- world3_clip(2, w$dcfsn * w$frsn[k] * w$sfsn[k], w$time[k], w$zpgt)
  w$ple[k] <- world3_dlinf3(w$delay$dlinf3_le, k, w$lpd)
  w$cmple[k] <- w$fn$cmple(w$ple[k])
  w$dtf[k] <- w$dcfs[k] * w$cmple[k]
  w$fm[k] <- w$fn$fm(w$le[k])
  w$mtf[k] <- w$mtfn * w$fm[k]
  w$nfc[k] <- w$mtf[k] / w$dtf[k] - 1
  w$fsafc[k] <- w$fn$fsafc(w$nfc[k])
  w$fcapc[k] <- w$fsafc[k] * w$sopc[k]
  w <- world3_sync_delays(w)
  w$fcfpc[k] <- world3_dlinf3(w$delay$dlinf3_fcapc, k, w$hsid)
  w$fce[k] <- world3_clip(1, w$fn$fce_toclip(w$fcfpc[k]), w$time[k], w$fcest)
  w$tf[k] <- min(w$mtf[k], w$mtf[k] * (1 - w$fce[k]) + w$dtf[k] * w$fce[k])
  w$cbr[k] <- 1000 * w$b[jk] / w$pop[k]
  w$b[kl] <- world3_clip(w$d[k], w$tf[k] * w$p2[k] * 0.5 / w$rlt, w$time[k], w$pet)
  w$lei[k] <- w$fn$lei(w$le[k])
  w$gdpc[k] <- w$fn$gdpc(w$iopc[k])
  w$gdpi[k] <- (log(w$gdpc[k]) - log(24)) / (log(9508) - log(24))
  w$ei[k] <- w$fn$ei(w$gdpc[k])
  w$hwi[k] <- (w$lei[k] + w$ei[k] + w$gdpi[k]) / 3
  w
}

world3_update_capital <- function(w, k, j = k - 1, jk = j, kl = k, state = TRUE) {
  w <- world3_sync_delays(w)
  w$lufd[k] <- world3_smooth(w$delay$smooth_luf, k, w$lufdt, 1)
  w$cuf[k] <- w$fn$cuf(w$lufd[k])
  if (state) w$ic[k] <- w$ic[j] + w$dt * (w$icir[jk] - w$icdr[jk])
  w$alic[k] <- world3_clip(w$alic2, w$alic1, w$time[k], w$pyear)
  w$icdr[kl] <- w$ic[k] / w$alic[k]
  w$icor[k] <- world3_clip(w$icor2, w$icor1, w$time[k], w$pyear)
  w$io[k] <- w$ic[k] * (1 - w$fcaor[k]) * w$cuf[k] / w$icor[k]
  w$iopc[k] <- w$io[k] / w$pop[k]
  w$fioacv[k] <- w$fn$fioacv(w$iopc[k] / w$iopcd)
  w$fioacc[k] <- world3_clip(w$fioac2, w$fioac1, w$time[k], w$pyear)
  w$fioac[k] <- world3_clip(w$fioacv[k], w$fioacc[k], w$time[k], w$iet)
  w$cio[k] <- w$fioac[k] * w$io[k]
  w$ciopc[k] <- w$cio[k] / w$pop[k]
  if (state) w$sc[k] <- w$sc[j] + w$dt * (w$scir[jk] - w$scdr[jk])
  w$isopc1[k] <- w$fn$isopc1(w$iopc[k]); w$isopc2[k] <- w$fn$isopc2(w$iopc[k])
  w$isopc[k] <- world3_clip(w$isopc2[k], w$isopc1[k], w$time[k], w$pyear)
  w$alsc[k] <- world3_clip(w$alsc2, w$alsc1, w$time[k], w$pyear)
  w$scdr[kl] <- w$sc[k] / w$alsc[k]
  w$scor[k] <- world3_clip(w$scor2, w$scor1, w$time[k], w$pyear)
  w$so[k] <- w$sc[k] * w$cuf[k] / w$scor[k]
  w$sopc[k] <- w$so[k] / w$pop[k]
  w$fioas1[k] <- w$fn$fioas1(w$sopc[k] / w$isopc[k])
  w$fioas2[k] <- w$fn$fioas2(w$sopc[k] / w$isopc[k])
  w$fioas[k] <- world3_clip(w$fioas2[k], w$fioas1[k], w$time[k], w$pyear)
  w$scir[kl] <- w$io[k] * w$fioas[k]
  w$fioai[k] <- 1 - w$fioaa[k] - w$fioas[k] - w$fioac[k]
  w$icir[kl] <- w$io[k] * w$fioai[k]
  w$jpicu[k] <- w$fn$jpicu(w$iopc[k]); w$pjis[k] <- w$ic[k] * w$jpicu[k]
  w$jpscu[k] <- w$fn$jpscu(w$sopc[k]); w$pjss[k] <- w$sc[k] * w$jpscu[k]
  w$jph[k] <- w$fn$jph(w$aiph[k]); w$pjas[k] <- w$jph[k] * w$al[k]
  w$j[k] <- w$pjis[k] + w$pjas[k] + w$pjss[k]
  w$lf[k] <- (w$p2[k] + w$p3[k]) * w$lfpf
  w$luf[k] <- w$j[k] / w$lf[k]
  w
}

world3_update_agriculture <- function(w, k, j = k - 1, jk = j, kl = k, state = TRUE) {
  if (state) {
    w$al[k] <- w$al[j] + w$dt * (w$ldr[jk] - w$ler[jk] - w$lrui[jk])
    w$pal[k] <- w$pal[j] - w$dt * w$ldr[jk]
    w$uil[k] <- w$uil[j] + w$dt * w$lrui[jk]
    w$lfert[k] <- w$lfert[j] + w$dt * (w$lfr[jk] - w$lfd[jk])
    w$ai[k] <- w$ai[j] + w$dt * w$aic[jk]
  }
  w$lfc[k] <- w$al[k] / w$palt
  w$ifpc1[k] <- w$fn$ifpc1(w$iopc[k]); w$ifpc2[k] <- w$fn$ifpc2(w$iopc[k])
  w$ifpc[k] <- world3_clip(w$ifpc2[k], w$ifpc1[k], w$time[k], w$pyear)
  w$dcph[k] <- w$fn$dcph(w$pal[k] / w$palt)
  w$pfr[k] <- if (k == 1) w$pfr[k] else w$pfr[j] + w$dt * w$cpfr[j]
  w$falm[k] <- w$fn$falm(w$pfr[k])
  w$aiph[k] <- w$ai[k] * (1 - w$falm[k]) / w$al[k]
  w$lymc[k] <- w$fn$lymc(w$aiph[k])
  w$mlymc[k] <- w$fn$mlymc(w$aiph[k])
  w$lymap1[k] <- w$fn$lymap1(w$io[k] / w$io70)
  w$lymap2[k] <- w$fn$lymap2(w$io[k] / w$io70)
  w$lymap[k] <- world3_clip(w$lymap2[k], w$lymap1[k], w$time[k], w$pyear)
  w <- world3_sync_delays(w)
  w$lyf2[k] <- world3_dlinf3(w$delay$dlinf3_yt, k, w$tdt)
  w$lyf[k] <- world3_clip(w$lyf2[k], w$lyf1, w$time[k], w$pyear_y_tech)
  w$ly[k] <- w$lyf[k] * w$lfert[k] * w$lymc[k] * w$lymap[k]
  w$f[k] <- w$ly[k] * w$al[k] * w$lfh * (1 - w$pl)
  w$fpc[k] <- w$f[k] / w$pop[k]
  w$fioaa1[k] <- w$fn$fioaa1(w$fpc[k] / w$ifpc[k])
  w$fioaa2[k] <- w$fn$fioaa2(w$fpc[k] / w$ifpc[k])
  w$fioaa[k] <- world3_clip(w$fioaa2[k], w$fioaa1[k], w$time[k], w$pyear)
  w$tai[k] <- w$io[k] * w$fioaa[k]
  w$alai[k] <- world3_clip(w$alai2, w$alai1, w$time[k], w$pyear)
  w$mpai[k] <- w$alai[k] * w$ly[k] * w$mlymc[k] / w$lymc[k]
  w$mpld[k] <- w$ly[k] / (w$dcph[k] * w$sd)
  w$fiald[k] <- w$fn$fiald(w$mpld[k] / w$mpai[k])
  w$ldr[kl] <- w$tai[k] * w$fiald[k] / w$dcph[k]
  w$cai[k] <- w$tai[k] * (1 - w$fiald[k])
  w$aic[k] <- (w$cai[k] - w$ai[k]) / w$alai[k]
  w$fr[k] <- w$fpc[k] / w$sfpc
  w$cpfr[k] <- (w$fr[k] - w$pfr[k]) / w$fspd
  w$lfdr[k] <- w$fn$lfdr(w$ppolx[k])
  w$lfd[kl] <- w$lfert[k] * w$lfdr[k]
  w$llmy1[k] <- w$fn$llmy1(w$ly[k] / w$ilf)
  w$llmy2[k] <- w$fn$llmy2(w$ly[k] / w$ilf)
  w$llmy[k] <- world3_clip(w$llmy2[k], w$llmy1[k], w$time[k], w$pyear)
  w$all[k] <- w$alln * w$llmy[k]
  w$ler[kl] <- w$al[k] / w$all[k]
  w$uilpc[k] <- w$fn$uilpc(w$iopc[k])
  w$uilr[k] <- w$uilpc[k] * w$pop[k]
  w$lrui[kl] <- max(0, (w$uilr[k] - w$uil[k]) / w$uildt)
  w$lfrt[k] <- w$fn$lfrt(w$falm[k])
  w$lfr[kl] <- (w$ilf - w$lfert[k]) / w$lfrt[k]
  w$frd[k] <- w$dfr - w$fr[k]
  w$ytcm[k] <- w$fn$ytcm(w$frd[k])
  w$ytcr[k] <- if (w$time[k] < w$pyear_y_tech) 0 else w$ytcm[k] * w$yt[j]
  w$yt[k] <- if (k == 1) w$yt[k] else w$yt[j] + w$dt * w$ytcr[k]
  w
}

world3_update_pollution <- function(w, k, j = k - 1, jk = j, state = TRUE) {
  w$pcrum[k] <- w$fn$pcrum(w$iopc[k])
  if (state) w$pp[k] <- w$pp[j] + w$dt * (w$ppar[jk] - w$ppasr[jk])
  w$ppolx[k] <- w$pp[k] / w$pp70
  w$ppgi[k] <- w$pcrum[k] * w$pop[k] * w$frpm * w$imef * w$imti
  w$ppga[k] <- w$aiph[k] * w$al[k] * w$faipm * w$amti
  w$ppgf[k] <- world3_clip(w$ppgf2[k], w$ppgf1, w$time[k], w$pyear_pp_tech)
  w$ppgr[k] <- (w$ppgi[k] + w$ppga[k]) * w$ppgf[k]
  w <- world3_sync_delays(w)
  w$ppar[k] <- world3_dlinf3(w$delay$dlinf3_ppgr, k, w$pptd)
  w$ahlm[k] <- w$fn$ahlm(w$ppolx[k])
  w$ahl[k] <- w$ahl70 * w$ahlm[k]
  w$ppasr[k] <- w$pp[k] / (1.4 * w$ahl[k])
  w$pptc[k] <- 1 - (w$ppolx[k] / w$dppolx)
  w$pptcm[k] <- w$fn$pptcm(w$pptc[k])
  w$pptcr[k] <- if (w$time[k] >= w$pyear_pp_tech) w$pptcm[j] * w$ppt[j] else 0
  w$ppt[k] <- if (k == 1) w$ppt[k] else w$ppt[j] + w$dt * w$pptcr[k]
  w <- world3_sync_delays(w)
  w$ppgf2[k] <- world3_dlinf3(w$delay$dlinf3_ppt, k, w$tdt)
  w$pptmi[k] <- w$fn$pptmi(w$ppgf[k])
  w$pii[k] <- w$ppgi[k] * w$ppgf[k] / w$io[k]
  w$fio70[k] <- w$io[k] / w$io70
  w$ymap1[k] <- w$fn$ymap1(w$fio70[k]); w$ymap2[k] <- w$fn$ymap2(w$fio70[k])
  w$apfay[k] <- if (w$time[k] > w$apct) w$ymap2[k] else w$ymap1[k]
  w$abl[k] <- w$ppgr[k] * w$ghup
  w$ef[k] <- (w$al[k] / 1e9 + w$uil[k] / 1e9 + w$abl[k]) / 1.91
  w
}

world3_update_resource <- function(w, k, j = k - 1, jk = j, kl = k, state = TRUE) {
  if (state) w$nr[k] <- w$nr[j] - w$dt * w$nrur[jk]
  w$nrfr[k] <- w$nr[k] / w$nri
  w$fcaor1[k] <- w$fn$fcaor1(w$nrfr[k]); w$fcaor2[k] <- w$fn$fcaor2(w$nrfr[k])
  w$fcaor[k] <- world3_clip(w$fcaor2[k], w$fcaor1[k], w$time[k], w$pyear_fcaor)
  w <- world3_sync_delays(w)
  w$nruf2[k] <- world3_dlinf3(w$delay$dlinf3_rt, k, w$tdt)
  w$nruf[k] <- world3_clip(w$nruf2[k], w$nruf1, w$time[k], w$pyear_res_tech)
  w$pcrum[k] <- w$fn$pcrum(w$iopc[k])
  w$nrur[kl] <- w$pop[k] * w$pcrum[k] * w$nruf[k]
  w$rtc[k] <- 1 - w$nrur[k] / w$drur
  w$rtcm[k] <- w$fn$rtcm(w$rtc[k])
  w$rtcr[k] <- if (w$time[k] > w$pyear_res_tech) w$rtcm[k] * w$rt[k - 1] else 0
  w$rt[k] <- if (k == 1) w$rt[k] else w$rt[j] + w$dt * w$rtcr[k]
  w
}

world3_initialize <- function(w) {
  w$p1[1] <- w$p1i; w$p2[1] <- w$p2i; w$p3[1] <- w$p3i; w$p4[1] <- w$p4i
  w$frsn[1] <- 0.82
  w$pop[1] <- w$p1[1] + w$p2[1] + w$p3[1] + w$p4[1]
  w$ic[1] <- w$ici; w$sc[1] <- w$sci
  w$al[1] <- w$ali; w$pal[1] <- w$pali; w$uil[1] <- w$uili
  w$lfert[1] <- w$lferti; w$ai[1] <- 5e9; w$pfr[1] <- 1
  w$yt[1] <- 1; w$ytcr[1] <- 0
  w$pp[1] <- w$pp19; w$ppt[1] <- 1
  w$nr[1] <- w$nri; w$rt[1] <- 1
  w$nrur[1] <- 0
  w$ppar[1] <- 0
  w$ppasr[1] <- 0

  for (iter in seq_len(8)) {
    w <- world3_update_population(w, 1, 1, 1, 1, state = FALSE)
    w <- world3_update_resource(w, 1, 1, 1, 1, state = FALSE)
    w <- world3_update_capital(w, 1, 1, 1, 1, state = FALSE)
    w <- world3_update_pollution(w, 1, 1, 1, state = FALSE)
    w <- world3_update_agriculture(w, 1, 1, 1, 1, state = FALSE)
  }
  w
}

run_world3_03 <- function(year_min = 1900, year_max = 2100, dt = 0.5,
                          pyear = 1975, pyear_res_tech = 4000,
                          pyear_pp_tech = 4000, pyear_fcaor = 4000,
                          pyear_y_tech = 4000, iphst = 1940,
                          constants = list(), tables_file = NULL) {
  w <- world3_empty(year_min, year_max, dt, pyear, pyear_res_tech,
                    pyear_pp_tech, pyear_fcaor, pyear_y_tech, iphst,
                    tables_file)
  for (nm in names(constants)) w[[nm]] <- constants[[nm]]
  w <- world3_initialize(w)

  if (w$n > 1) {
    for (k in 2:w$n) {
      j <- k - 1; jk <- j; kl <- k
      w <- world3_update_population(w, k, j, jk, kl, state = TRUE)
      w <- world3_update_resource(w, k, j, jk, kl, state = TRUE)
      w <- world3_update_capital(w, k, j, jk, kl, state = TRUE)
      w <- world3_update_pollution(w, k, j, jk, state = TRUE)
      w <- world3_update_agriculture(w, k, j, jk, kl, state = TRUE)
      w <- world3_update_population(w, k, j, jk, kl, state = FALSE)
      w <- world3_update_resource(w, k, j, jk, kl, state = FALSE)
      w <- world3_update_capital(w, k, j, jk, kl, state = FALSE)
      w <- world3_update_pollution(w, k, j, jk, state = FALSE)
    }
  }

  class(w) <- c("world3_03", class(w))
  w
}

as.data.frame.world3_03 <- function(x, ...) {
  vars <- names(x)[vapply(x, function(v) is.numeric(v) && length(v) == x$n, logical(1))]
  out <- as.data.frame(x[vars], optional = TRUE)
  out$time <- x$time
  out[, c("time", setdiff(names(out), "time"))]
}

world3_key_series <- function(w) {
  df <- as.data.frame(w)
  df[, c("time", "pop", "nrfr", "fpc", "iopc", "ppolx", "io", "f", "le", "sopc", "ciopc", "hwi", "ef")]
}
