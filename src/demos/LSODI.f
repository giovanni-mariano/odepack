
c-----------------------------------------------------------------------
c Demonstration program for the DLSODI package.
c This is the version of 14 June 2001.
c
c This version is in double precision.
c
C this program solves a semi-discretized form of the Burgers equation,
c
c     u  = -(u*u/2)  + eta * u
c      t           x          xx
c
c for a = -1 .le. x .le. 1 = b, t .ge. 0.
c Here eta = 0.05.
c Boundary conditions: u(-1,t) = u(1,t) = 0.
c Initial profile: square wave
c     u(0,x) = 0    for 1/2 .lt. abs(x) .le. 1
c     u(0,x) = 1/2  for abs(x) = 1/2
c     u(0,x) = 1    for 0 .le. abs(x) .lt. 1/2
c
c An ODE system is generated by a simplified Galerkin treatment
c of the spatial variable x.
c
c Reference:
c R. C. Y. Chin, G. W. Hedstrom, and K. E. Karlsson,
c A Simplified Galerkin Method for Hyperbolic Equations,
c Math. Comp., vol. 33, no. 146 (April 1979), pp. 647-658.
c
c The problem is run with the DLSODI package with a 10-point mesh
c and a 100-point mesh.  In each case, it is run with two tolerances
c and for various appropriate values of the method flag mf.
c Output is on unit lout, set to 6 in a data statement below.
c-----------------------------------------------------------------------
      external res, addabd, addafl, jacbd, jacfl
      integer i, io, istate, itol, iwork, j,
     1   lout, liw, lrw, meth, miter, mf, ml, mu,
     2   n, nout, npts, nerr,
     3   nptsm1, n14, n34, n14m1, n14p1, n34m1, n34p1
      integer nm1
      double precision a, b, eta, delta,
     1   zero, fourth, half, one, hun,
     2   t, tout, tlast, tinit, errfac,
     3   atol, rtol, rwork, y, ydoti, elkup
      double precision eodsq, r4d
      dimension y(99), ydoti(99), tout(4), atol(2), rtol(2)
      dimension rwork(2002), iwork(125)
c Pass problem parameters in the Common block test1.
      common /test1/ r4d, eodsq, nm1
c
c Set problem parameters and run parameters
      data eta/0.05d0/, a/-1.0d0/, b/1.0d0/
      data zero/0.0d0/, fourth/0.25d0/, half/.5d0/, one/1.0d0/,
     1   hun/100.0d0/
      data tinit/0.0d0/, tlast/0.4d0/
      data tout/.10d0,.20d0,.30d0,.40d0/
      data ml/1/, mu/1/, lout/6/
      data nout/4/, lrw/2002/, liw/125/
      data itol/1/, rtol/1.0d-3, 1.0d-6/, atol/1.0d-3, 1.0d-6/
c
      iwork(1) = ml
      iwork(2) = mu
      nerr = 0
c
c Loop over two values of npts.
      do 300  npts = 10, 100, 90
c
c Compute the mesh width delta and other parameters.
      delta = (b - a)/npts
      r4d = fourth/delta
      eodsq = eta/delta**2
      nptsm1 = npts - 1
      n14 = npts/4
      n34 = 3 * n14
      n14m1 = n14 - 1
      n14p1 = n14m1 + 2
      n34m1 = n34 - 1
      n34p1 = n34m1 + 2
      n = nptsm1
      nm1 = n - 1
c
c Set the initial profile (for output purposes only).
c
      do 10 i = 1,n14m1
   10   y(i) = zero
      y(n14) = half
      do 20 i = n14p1,n34m1
   20   y(i) = one
      y(n34) = half
      do 30 i = n34p1,nptsm1
   30   y(i) = zero
c
      if (npts .gt. 10) write (lout,1010)
      write (lout,1000)
      write (lout,1100) eta,a,b,tinit,tlast,ml,mu,n
      write (lout,1200) zero, (y(i), i=1,n), zero
c
c The j loop is over error tolerances.
c
      do 200 j = 1,2
c
c Loop over method flag loop (for demonstration).
c
      do 100 meth = 1,2
       do 100 miter = 1,5
        if (miter .eq. 3)  go to 100
        if (miter .le. 2 .and. npts .gt. 10)  go to 100
        if (miter .eq. 5 .and. npts .lt. 100)  go to 100
        mf = 10*meth + miter
c
c Set the initial profile.
c
        do 40 i = 1,n14m1
   40     y(i) = zero
        y(n14) = half
        do 50 i = n14p1,n34m1
   50     y(i) = one
        y(n34) = half
        do 60 i = n34p1,nptsm1
   60     y(i) = zero
c
        t = tinit
        istate = 0
c
        write (lout,1500) rtol(j), atol(j), mf, npts
c
c  Output loop for each case
c
        do 80 io = 1,nout
c
c         call DLSODI
          if (miter .le. 2) call dlsodi (res, addafl, jacfl, n, y,
     1                      ydoti, t, tout(io), itol, rtol(j), atol(j),
     2                      1, istate, 0, rwork, lrw, iwork, liw, mf)
          if (miter .ge. 4) call dlsodi (res, addabd, jacbd, n, y,
     1                      ydoti, t, tout(io), itol, rtol(j), atol(j),
     2                      1, istate, 0, rwork, lrw, iwork, liw, mf)
          write (lout,2000) t, rwork(11), iwork(14),(y(i), i=1,n)
c
c If istate is not 2 on return, print message and loop.
          if (istate .ne. 2) then
            write (lout,4000) mf, t, istate
            nerr = nerr + 1
            go to 100
          endif
c
   80     continue
c
        write (lout,3000) mf, iwork(11), iwork(12), iwork(13),
     1                iwork(17), iwork(18)
c
c Estimate final error and print result.
        errfac = elkup( n, y, rwork(21), itol, rtol(j), atol(j) )
        if (errfac .gt. hun) then
          write (lout,5001)  errfac
          nerr = nerr + 1
        else
          write (lout,5000)  errfac
        endif
  100   continue
  200 continue
  300 continue
c
      write (lout,6000) nerr
      stop
c
 1000 format(20x,' Demonstration Problem for DLSODI')
 1010 format(///80('*')///)
 1100 format(/10x,' Simplified Galerkin Solution of Burgers Equation'//
     1       13x,'Diffusion coefficient is eta =',d10.2/
     2       13x,'Uniform mesh on interval',d12.3,' to ',d12.3/
     3       13x,'Zero boundary conditions'/
     4       13x,'Time limits: t0 = ',d12.5,'   tlast = ',d12.5/
     5       13x,'Half-bandwidths ml = ',i2,'   mu = ',i2/
     6       13x,'System size neq = ',i3/)
c
 1200 format('Initial profile:'/17(6d12.4/))
c
 1500 format(///80('-')///'Run with rtol =',d12.2,'  atol =',d12.2,
     1       '   mf =',i3,'   npts =',i4,':'//)
c
 2000 format('Output for time t = ',d12.5,'   current h =',
     1       d12.5,'   current order =',i2,':'/17(6d12.4/))
c
 3000 format(//'Final statistics for mf = ',i2,':'/
     1       i4,' steps,',i5,' res,',i4,' Jacobians,',
     2       '   rwork size =',i6,',   iwork size =',i6)
c
 4000 format(///80('*')//20x,'Final time reached for mf = ',i2,
     1       ' was t = ',d12.5/25x,'at which istate = ',i2////80('*'))
 5000 format('  Final output is correct to within ',d8.1,
     1       '  times local error tolerance')
 5001 format('  Final output is wrong by ',d8.1,
     1       '  times local error tolerance')
 6000 format(//80('*')//
     1       'Run completed.  Number of errors encountered =',i3)
c
c end of main program for the DLSODI demonstration problem.
      end

      subroutine res (n, t, y, v, r, ires)
c This subroutine computes the residual vector
c   r = g(t,y) - A(t,y)*v .
c It uses nm1 = n - 1 from Common.
c If ires = -1, only g(t,y) is returned in r, since A(t,y) does
c not depend on y.
c
      integer i, ires, n, nm1
      double precision t, y, v, r, r4d, eodsq, one, four, six,
     1   fact1, fact4
      dimension y(n), v(n), r(n)
      common /test1/ r4d, eodsq, nm1
      data one /1.0d0/, four /4.0d0/, six /6.0d0/
c
      call gfun (n, t, y, r)
      if (ires .eq. -1) return
c
      fact1 = one/six
      fact4 = four/six
      r(1) = r(1) - (fact4*v(1) + fact1*v(2))
      do 10 i = 2, nm1
  10   r(i) = r(i) - (fact1*v(i-1) + fact4*v(i) + fact1*v(i+1))
      r(n) = r(n) - (fact1*v(nm1) + fact4*v(n))
      return
c end of subroutine res for the DLSODI demonstration problem.
      end

      subroutine gfun (n, t, y, g)
c This subroutine computes the right-hand side function g(y,t).
c It uses r4d = 1/(4*delta), eodsq = eta/delta**2, and nm1 = n - 1
c from the Common block test1.
c
      integer i, n, nm1
      double precision t, y, g, r4d, eodsq, two
      dimension g(n), y(n)
      common /test1/ r4d, eodsq, nm1
      data two/2.0d0/
c
      g(1) = -r4d*y(2)**2 + eodsq*(y(2) - two*y(1))
c
      do 20 i = 2,nm1
        g(i) = r4d*(y(i-1)**2 - y(i+1)**2)
     1        + eodsq*(y(i+1) - two*y(i) + y(i-1))
   20   continue
c
      g(n) = r4d*y(nm1)**2 + eodsq*(y(nm1) - two*y(n))
c
      return
c end of subroutine gfun for the DLSODI demonstration problem.
      end

      subroutine addabd (n, t, y, ml, mu, pa, m0)
c This subroutine computes the matrix A in band form, adds it to pa,
c and returns the sum in pa.   The matrix A is tridiagonal, of order n,
c with nonzero elements (reading across) of  1/6, 4/6, 1/6.
c
      integer i, n, m0, ml, mu, mup1, mup2
      double precision t, y, pa, fact1, fact4, one, four, six
      dimension y(n), pa(m0,n)
      data one/1.0d0/, four/4.0d0/, six/6.0d0/
c
c Set the pointers.
      mup1 = mu + 1
      mup2 = mu + 2
c Compute the elements of A.
      fact1 = one/six
      fact4 = four/six
c Add the matrix A to the matrix pa (banded).
      do 10 i = 1,n
        pa(mu,i) = pa(mu,i) + fact1
        pa(mup1,i) = pa(mup1,i) + fact4
        pa(mup2,i) = pa(mup2,i) + fact1
   10   continue
      return
c end of subroutine addabd for the DLSODI demonstration problem.
      end

      subroutine addafl (n, t, y, ml, mu, pa, m0)
c This subroutine computes the matrix A in full form, adds it to
c pa, and returns the sum in pa.
c It uses nm1 = n - 1 from Common.
c The matrix A is tridiagonal, of order n, with nonzero elements
c (reading across) of  1/6, 4/6, 1/6.
c
      integer i, n, m0, ml, mu, nm1
      double precision t, y, pa, r4d, eodsq, one, four, six,
     1   fact1, fact4
      dimension y(n), pa(m0,n)
      common /test1/ r4d, eodsq, nm1
      data one/1.0d0/, four/4.0d0/, six/6.0d0/
c
c Compute the elements of A.
      fact1 = one/six
      fact4 = four/six
c
c Add the matrix A to the matrix pa (full).
c
      do 110  i = 2, nm1
         pa(i,i+1) = pa(i,i+1) + fact1
         pa(i,i) = pa(i,i) + fact4
         pa(i,i-1) = pa(i,i-1) + fact1
  110    continue
      pa(1,2) = pa(1,2) + fact1
      pa(1,1) = pa(1,1) + fact4
      pa(n,n) = pa(n,n) + fact4
      pa(n,nm1) = pa(n,nm1) + fact1
      return
c end of subroutine addafl for the DLSODI demonstration problem.
      end

      subroutine jacbd (n, t, y, s, ml, mu, pa, m0)
c This subroutine computes the Jacobian dg/dy = d(g-a*s)/dy
c and stores elements
c   i   j
c dg /dy   in  pa(i-j+mu+1,j)  in band matrix format.
c It uses r4d = 1/(4*delta), eodsq = eta/delta**2, and nm1 = n - 1
c from the Common block test1.
c
      integer i, n, m0, ml, mu, mup1, mup2, nm1
      double precision t, y, s, pa, diag, r4d, eodsq, two, r2d
      dimension y(n), s(n), pa(m0,n)
      common /test1/ r4d, eodsq, nm1
      data two/2.0d0/
c
      mup1 = mu + 1
      mup2 = mu + 2
      diag = -two*eodsq
      r2d = two*r4d
c                     1   1
c Compute and store dg /dy
      pa(mup1,1) = diag
c
c                     1   2
c Compute and store dg /dy
      pa(mu,2) = -r2d*y(2) + eodsq
c
      do 20 i = 2,nm1
c
c                     i   i-1
c Compute and store dg /dy
        pa(mup2,i-1) = r2d*y(i-1) + eodsq
c
c                     i   i
c Compute and store dg /dy
      pa(mup1,i) = diag
c
c                     i   i+1
c Compute and store dg /dy
        pa(mu,i+1) = -r2d*y(i+1) + eodsq
   20   continue
c
c                     n   n-1
c Compute and store dg /dy
      pa(mup2,nm1) = r2d*y(nm1) + eodsq
c
c                     n   n
c Compute and store dg /dy
      pa(mup1,n) = diag
c
      return
c end of subroutine jacbd for the DLSODI demonstration problem.
      end

      subroutine jacfl (n, t, y, s, ml, mu, pa, m0)
c This subroutine computes the Jacobian dg/dy = d(g-a*s)/dy
c and stores elements
c   i   j
c dg /dy   in  pa(i,j) in full matrix format.
c It uses r4d = 1/(4*delta), eodsq = eta/delta**2, and nm1 = n - 1
c from the Common block test1.
c
      integer i, n, m0, ml, mu, nm1
      double precision t, y, s, pa, diag, r4d, eodsq, two, r2d
      dimension y(n), s(n), pa(m0,n)
      common /test1/ r4d, eodsq, nm1
      data two/2.0d0/
c
      diag = -two*eodsq
      r2d = two*r4d
c
c                     1   1
c Compute and store dg /dy
      pa(1,1) = diag
c
c                     1   2
c Compute and store dg /dy
      pa(1,2) = -r2d*y(2) + eodsq
c
      do 120  i = 2,nm1
c
c                     i   i-1
c Compute and store dg /dy
        pa(i,i-1) = r2d*y(i-1) + eodsq
c
c                     i   i
c Compute and store dg /dy
      pa(i,i) = diag
c
c                     i   i+1
c Compute and store dg /dy
        pa(i,i+1) = -r2d*y(i+1) + eodsq
  120   continue
c
c                     n   n-1
c Compute and store dg /dy
      pa(n,nm1) = r2d*y(nm1) + eodsq
c
c                     n   n
c Compute and store dg /dy
      pa(n,n) = diag
c
      return
c end of subroutine jacfl for the DLSODI demonstration problem.
      end

      double precision function elkup (n, y, ewt, itol, rtol, atol)
c This routine looks up approximately correct values of y at t = 0.4,
c ytrue = y9 or y99 depending on whether n = 9 or 99.  These were
c obtained by running DLSODI with very tight tolerances.
c The returned value is
c elkup  =  norm of  ( y - ytrue ) / ( rtol*abs(ytrue) + atol ).
c
      integer n, itol, i
      double precision y, ewt, rtol, atol, y9, y99, y99a, y99b, y99c,
     1   y99d, y99e, y99f, y99g, dvnorm
      dimension y(n), ewt(n), y9(9), y99(99)
      dimension y99a(16), y99b(16), y99c(16), y99d(16), y99e(16),
     1          y99f(16), y99g(3)
      equivalence (y99a(1),y99(1)), (y99b(1),y99(17)),
     1      (y99c(1),y99(33)), (y99d(1),y99(49)), (y99e(1),y99(65)),
     1      (y99f(1),y99(81)), (y99g(1),y99(97))
      data y9 /
     1 1.07001457d-01, 2.77432492d-01, 5.02444616d-01, 7.21037157d-01,
     1 9.01670441d-01, 8.88832048d-01, 4.96572850d-01, 9.46924362d-02,
     1-6.90855199d-03 /
      data y99a /
     1 2.05114384d-03, 4.19527452d-03, 6.52533872d-03, 9.13412751d-03,
     1 1.21140191d-02, 1.55565301d-02, 1.95516488d-02, 2.41869487d-02,
     1 2.95465081d-02, 3.57096839d-02, 4.27498067d-02, 5.07328729d-02,
     1 5.97163151d-02, 6.97479236d-02, 8.08649804d-02, 9.30936515d-02 /
      data y99b /
     1 1.06448659d-01, 1.20933239d-01, 1.36539367d-01, 1.53248227d-01,
     1 1.71030869d-01, 1.89849031d-01, 2.09656044d-01, 2.30397804d-01,
     1 2.52013749d-01, 2.74437805d-01, 2.97599285d-01, 3.21423708d-01,
     1 3.45833531d-01, 3.70748792d-01, 3.96087655d-01, 4.21766871d-01 /
      data y99c /
     1 4.47702161d-01, 4.73808532d-01, 5.00000546d-01, 5.26192549d-01,
     1 5.52298887d-01, 5.78234121d-01, 6.03913258d-01, 6.29252015d-01,
     1 6.54167141d-01, 6.78576790d-01, 7.02400987d-01, 7.25562165d-01,
     1 7.47985803d-01, 7.69601151d-01, 7.90342031d-01, 8.10147715d-01 /
      data y99d /
     1 8.28963844d-01, 8.46743353d-01, 8.63447369d-01, 8.79046021d-01,
     1 8.93519106d-01, 9.06856541d-01, 9.19058529d-01, 9.30135374d-01,
     1 9.40106872d-01, 9.49001208d-01, 9.56853318d-01, 9.63702661d-01,
     1 9.69590361d-01, 9.74555682d-01, 9.78631814d-01, 9.81840924d-01 /
      data y99e /
     1 9.84188430d-01, 9.85656465d-01, 9.86196496d-01, 9.85721098d-01,
     1 9.84094964d-01, 9.81125395d-01, 9.76552747d-01, 9.70041743d-01,
     1 9.61175143d-01, 9.49452051d-01, 9.34294085d-01, 9.15063568d-01,
     1 8.91098383d-01, 8.61767660d-01, 8.26550038d-01, 7.85131249d-01 /
      data y99f /
     1 7.37510044d-01, 6.84092540d-01, 6.25748369d-01, 5.63802368d-01,
     1 4.99946558d-01, 4.36077986d-01, 3.74091566d-01, 3.15672765d-01,
     1 2.62134958d-01, 2.14330497d-01, 1.72640946d-01, 1.37031155d-01,
     1 1.07140815d-01, 8.23867920d-02, 6.20562432d-02, 4.53794321d-02 /
      data y99g / 3.15789227d-02, 1.98968820d-02, 9.60472135d-03 /
c
      if (n .eq. 99) go to 99
c
c Compute local error tolerance using correct y (n = 9).
c
      call dewset( n, itol, rtol, atol, y9, ewt )
c
c Invert ewt and replace y by the error, y - ytrue.
c
      do 20  i = 1, 9
        ewt(i) = 1.0d0/ewt(i)
 20     y(i) = y(i) - y9(i)
      go to 200
c
c Compute local error tolerance using correct y (n = 99).
c
 99   call dewset( n, itol, rtol, atol, y99, ewt )
c
c Invert ewt and replace y by the error, y - ytrue.
c
      do 120  i = 1, 99
        ewt(i) = 1.0d0/ewt(i)
 120    y(i) = y(i) - y99(i)
c
c Find weighted norm of the error and return.
c
 200  elkup = dvnorm (n, y, ewt)
      return
c end of function elkup for the DLSODI demonstration program.
      end

