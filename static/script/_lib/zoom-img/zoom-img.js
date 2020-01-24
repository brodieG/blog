/*
Zoom Images

Suggested usage is adding

  ```{r child='../../static/script/_lib/zoom-img/zoom-img.Rmd', results='asis'}
  ```

To a post.  Automatically all imgs with class 'bgw-zoom-img' and a 'data-src-big' attribute with the location of the large image will be made zoomable

TODO:

* Nice smooth transition from existing image to modal
* Add ability to cycle through all zoomable images
* Add second level zoom
* Add capability to recover caption from original image

*/

function BgwZoomImages(x) {
  if(typeof(x) != 'string') {
    throw new Error("flipbook error: input is not an object");
  }
  let imgs = document.querySelectorAll('img.' + x);

  this.tarClass = x;
  this.activeEl = null;
  var zb = this;

  this.container = document.getElementById('bgw-zoom-img-container');
  if(this.container == null) {
    throw new Error("ZoomImages error: image container not found.");
  }
  if(this.container.children.length) {
    throw new Error(
      "ZoomImages error: container already instantiated, should only be one " +
      "of them per page."
    );
  }
  const zbImgTpl = document.getElementById('bgw-zoom-img-template');
  if(zbImgTpl == null) {
    throw new Error("ZoomImages error: image template not found.");
  }
  const zbFigTpl = document.getElementById('bgw-zoom-fig-template');
  if(zbFigTpl == null) {
    throw new Error("ZoomImages error: figure template not found.");
  }

  for(let i = 0; i < imgs.length; ++i) {
    if(typeof(imgs[i].getAttribute('data-src-big')) != 'string') {
      throw new Error("ZoomImages error: input lacking a srcBig attribute.");
    }
    /* Check what type we're dealing with */

    const isFig = imgs[i].parentElement.tagName == 'FIGURE';

    let figCapt = '';
    let zbTpl = null, zbPar = null, zbOut=null;

    if(isFig) {
      zbTpl = zbFigTpl;

      let dataCapt = imgs[i].getAttribute('data-caption');
      const figCapts = imgs[i].parentElement.getElementsByTagName('figcaption');
      if(typeof(dataCapt) == 'string') {
        figCapt = dataCapt;
      } else if (figCapts.length) {
        figCapt = figCapts[0].innerHTML;
      }
    } else {
      zbTpl = zbImgTpl;
    }
    const zbNew = zbTpl.cloneNode(true);
    zbNew.id = "";
    const zbClose = zbNew.getElementsByClassName('bgw-zoom-boxclose')[0];
    const zbImg = zbNew.getElementsByTagName('IMG')[0];

    if(isFig) {
      zbOut = zbNew.getElementsByTagName('FIGURE')[0];
      let zbCaptEl = zbNew.getElementsByTagName('FIGCAPTION')[0];
      if(figCapt.length) {
        zbCaptEl.innerHTML = figCapt;
      } else {
        zpCaptEl.style.display = 'none'
      }
    } else {
      zbOut = zbImg;
    }
    /* Initialize the modals */

    zbImg.src = imgs[i].getAttribute('data-src-big');

    if(typeof(zbImg.src) != 'string') {
      throw new
        Error("ZoomImages error: missing big image attribute for img " + i);
    }
    imgs[i].setAttribute('data-big-id', i);
    imgs[i].addEventListener("mouseup", function(e) {zb.showModal(e)});
    zbClose.addEventListener("mouseup", function(e) {zb.closeModal(e)});
    zbNew.addEventListener("mouseup", function(e) {zb.closeModal(e)});
    zbOut.addEventListener("mouseup", function(e) {e.stopPropagation();});
    document.addEventListener("keyup", function(e) {
      if(zb.activeEl != null) {
        zb.activeEl.style.display = 'none';
      }
      zb.activeEl = null;
    });
    this.container.append(zbNew);
  }
}
/*
 */
BgwZoomImages.prototype.showModal = function(e) {
  const img = e.target;
  const imgCont = document.getElementById('bgw-zoom-img-container').children
  const imgBig = imgCont[img.getAttribute('data-big-id')]
  imgBig.style.display='inline-block';
  this.activeEl = imgBig;

  // // Get coordinates for when we do smooth transition
  // const imgCoord = img.getBoundingClientRect();
}
/*
 * Handle closing of modal.  Super janky, need to cleanup some day (yeah right).
 */
BgwZoomImages.prototype.closeModal = function(e) {
  if(this.activeEl != null) {
    // for some inscrutable reason I was getting duplicate mouseup events, but
    // only with img, not fig templates, and only when clicking on closing box,
    // not on main div
    this.activeEl.style.display = 'none'
    this.activeEl = null;
  }
}
// zoom-imageize everything with class bgw-zoom-img

new BgwZoomImages('bgw-zoom-img');

