class PricingFeaturesView extends JView
  constructor: (options = {}, data) ->
    options.tagName  = "section"
    options.cssClass = KD.utils.curry "features", options.cssClass
    super options, data

  pistachio: ->
    """
    <div class='inner-container'>
      <h2 class="kdview kdheaderview general-title">
        <span>How our quotas work, every single part explained</span>
      </h2>
      <article class="feature">
        <i class="cpu icon"></i>
        <h5>CPU</h5>
        <p>
          Your CPUs are shared among all your running VMs. If you run only
          one VM, all CPUs will be utilized; if you have 10 VMs running,
          they will share your available CPUs.
        </p>
      </article>
      <article class="feature">
        <i class="ram icon"></i>
        <h5>RAM</h5>
        <p>
          Memory is shared between your running VMs. Each VM starts with
          allocated memory. If you have 10GB limit, you can run 10VMs at
          1GB, or 3 x 3GB or 1 x 10GB.
        </p>
      </article>
      <article class="feature">
        <i class="disk icon"></i>
        <h5>DISK</h5>
        <p>
          This is local storage allocated to your VMs. You can distribute
          this quota across all of your VMs as you need.You can allocate
          40GB of disk space to one of your VMs, for instance, and to the
          next one you could allocate 10GB.
        </p>
      </article>
      <article class="feature">
        <i class="always-on icon"></i>
        <h5>ALWAYS ON</h5>
        <p>
          The maximum number of VMs that you can keep turned on 24/7. For example,
          you bought a package that comes with 10 VMs and one always-on VM. The VM you
          mark as always-on will work 24/7, however the others will be powered off
          automatically 15 minutes after you log out.
        </p>
      </article>
    </div>
    """
