import{r as i}from"./vendor-b7b6560c.js";const d=()=>(i.useEffect(()=>{const a=()=>{const t=document.createElement("script");t.async=!0,t.src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX",document.head.appendChild(t),window.dataLayer=window.dataLayer||[];function e(...n){window.dataLayer.push(n)}window.gtag=e,e("js",new Date),e("config","G-XXXXXXXXXX",{page_title:document.title,page_location:window.location.href})},o=()=>{const t=document.createElement("script");t.innerHTML=`
        !function(f,b,e,v,n,t,s)
        {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
        n.callMethod.apply(n,arguments):n.queue.push(arguments)};
        if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
        n.queue=[];t=b.createElement(e);t.async=!0;
        t.src=v;s=b.getElementsByTagName(e)[0];
        s.parentNode.insertBefore(t,s)}(window, document,'script',
        'https://connect.facebook.net/en_US/fbevents.js');
        fbq('init', 'XXXXXXXXX'); // Replace with actual Pixel ID
        fbq('track', 'PageView');
      `,document.head.appendChild(t);const e=document.createElement("noscript");e.innerHTML=`
        <img height="1" width="1" style="display:none"
        src="https://www.facebook.com/tr?id=XXXXXXXXX&ev=PageView&noscript=1"/>
      `,document.body.appendChild(e)},c=()=>{const t=document.createElement("script");t.innerHTML=`
        (function(h,o,t,j,a,r){
          h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
          h._hjSettings={hjid:XXXXXXX,hjsv:6}; // Replace with actual Hotjar ID
          a=o.getElementsByTagName('head')[0];
          r=o.createElement('script');r.async=1;
          r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
          a.appendChild(r);
        })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
      `,document.head.appendChild(t)};a(),o(),c(),(()=>{document.addEventListener("click",e=>{const n=e.target;n.closest('[data-track="cta"]')&&(window.gtag&&window.gtag("event","cta_click",{event_category:"engagement",event_label:n.textContent}),window.fbq&&window.fbq("track","Lead")),n.closest('[data-track="course-page"]')&&window.gtag&&window.gtag("event","course_page_visit",{event_category:"navigation",event_label:n.textContent}),n.closest('[href*="tel:"]')&&window.gtag&&window.gtag("event","phone_click",{event_category:"contact",event_label:"phone_number"}),n.closest('[href*="wa.me"]')&&window.gtag&&window.gtag("event","whatsapp_click",{event_category:"contact",event_label:"whatsapp"})});let t=0;window.addEventListener("scroll",()=>{const e=Math.round(window.scrollY/(document.body.scrollHeight-window.innerHeight)*100);e>t&&(t=e,e>=25&&e<50?window.gtag&&window.gtag("event","scroll_depth",{event_category:"engagement",event_label:"25_percent"}):e>=50&&e<75?window.gtag&&window.gtag("event","scroll_depth",{event_category:"engagement",event_label:"50_percent"}):e>=75&&window.gtag&&window.gtag("event","scroll_depth",{event_category:"engagement",event_label:"75_percent"}))})})()},[]),null);export{d as A};
