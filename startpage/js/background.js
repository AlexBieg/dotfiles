(function() {
  class Point {
    constructor(x, y, dx, dy, r, maxDist) {
      this.x = x;
      this.y = y;
      this.dx = dx;
      this.dy = dy;
      this.r = r;
      this.maxDist = maxDist;
    }

    updatePoint(ctx) {
      this.x += this.dx;
      this.y += this.dy;

      // Loop points back around if they hit the edges of the screen
      if (this.x + this.r > ctx.canvas.width) {
        this.x = 0 + this.r;
      }

      if (this.x - this.r < 0) {
        this.x = ctx.canvas.width - this.r;
      }

      if (this.y + this.r > ctx.canvas.height) {
        this.y = 0 + this.r;
      }

      if (this.y - this.r < 0) {
        this.y = ctx.canvas.height - this.r;
      }
    }

    drawPoint(ctx) {
      ctx.fillStyle = '#34b1eb';
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.r, 0, 2*Math.PI);
      ctx.fill();
    }

    drawClosestLine(ctx, points) {
      points.forEach((point) => {
        const pointDist = Math.sqrt(Math.pow(point.x - this.x, 2) + Math.pow(point.y - this.y, 2));
        const percentage = 1 - (pointDist/this.maxDist);

        if (pointDist <= this.maxDist) {
          ctx.strokeStyle = '#34b1eb';
          ctx.lineWidth = percentage/2;
          ctx.beginPath();
          ctx.moveTo(this.x, this.y);
          ctx.lineTo(point.x, point.y);
          ctx.stroke();
        }
      });
    }
  }

  const canvas = document.getElementById('background');
  const ctx = canvas.getContext('2d');

  const width = window.innerWidth;
  const height = window.innerHeight;

  ctx.canvas.width = width;
  ctx.canvas.height = height;

  ctx.fillStyle = '#444444';
  ctx.fillRect(0, 0, width, height);

  const points = [];

  const initPoints = () => {
    // Determine number of points based on size of screen
    const numPoints = (width / 12) + (height / 12);
    for (let i = 0; i < numPoints; i++) {
      // Get a randome size
      const size = Math.random() * 2 + 1;

      // Set the connection range based on the size of the points
      const range = (size-1/2-1) * 100 + 50
      points.push(new Point(
        Math.random() * (width - 10) + 5,
        Math.random() * (height - 10) + 5,
        Math.random() * 1 - .5,
        Math.random() * 1 - .5,
        size,
        range
      ))
    }
  }

  const updatePoints = () => {
    points.forEach(p => {
      p.updatePoint(ctx);
      p.drawClosestLine(ctx, points);
      p.drawPoint(ctx)
    });
  }

  initPoints();

  setInterval(() => {
    const width = window.innerWidth;
    const height = window.innerHeight;

    ctx.canvas.width = width;
    ctx.canvas.height = height;

    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#444444';
    ctx.fillRect(0, 0, width, height);

    updatePoints()
  }, 10);
})();